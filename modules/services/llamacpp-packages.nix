{inputs, ...}: {
  # Tuned llama.cpp builds for the Strix Halo iGPU (Radeon 8060S, gfx1151).
  #
  # nixpkgs builds llama-cpp-rocm without rocWMMA flash-attention and without
  # hipBLASLt -- the two biggest prompt-processing accelerators on gfx1151.
  # Community benchmarks (https://llm-tracker.info/_TOORG/Strix-Halo): plain
  # HIP pp512 ~349 t/s vs ~986 t/s with rocWMMA+FA+hipBLASLt (Vulkan+FA ~884).
  #
  # Restricting rocmGpuTargets to gfx1151 plus these flags only rebuilds
  # llama.cpp itself (~minutes); all rocmPackages remain binary-cache hits.
  #
  # Fallback if this override ever breaks with a nixpkgs bump:
  # github:hellas-ai/nix-strix-halo maintains a pkgs.llamacpp-rocm.gfx1151
  # overlay with the same optimizations.
  # Benchmarks on avalon (Qwen3.6-27B Q4_K_M, 2026-07-06, llama.cpp b9842):
  #   rocm-strix:  pp512 290 t/s | pp4096 259 t/s | tg128 11.8 t/s
  #   vulkan-radv: pp512 313 t/s | pp4096 286 t/s | tg128 12.7 t/s  <- winner
  #
  # Source pin: nixpkgs is still on v1.0.0 (build 12359, 2026-11-25) and
  # upstream has not tagged a newer versioned release. Inkling 2
  # (inkling2_loop arch) needs build >= 12611 (PRs #32694 + #32704), so build
  # from a pinned upstream build tag instead. To bump: change the tag here and
  # llamaBuild below, `nix run .#write-flake`, then recompute npmDepsHash
  # (set to lib.fakeHash, build, paste the "got:" value) if
  # tools/ui/package-lock.json changed. Drop the pin once nixpkgs catches up.
  flake-file.inputs.llama-cpp-src = {
    url = "github:ggml-org/llama.cpp/b12756";
    flake = false;
  };

  flake.nixosModules.llamacpp-packages = {lib, ...}: let
    llamaSrc = inputs.llama-cpp-src;
    llamaBuild = "12756";
    llamaCommit = builtins.substring 0 7 llamaSrc.rev;
    # overrideAttrs re-runs the finalAttrs fixpoint, so the derivation's own
    # fetchNpmDeps picks up the new src and hash.
    pinSrc = pkg:
      pkg.overrideAttrs (_: old: {
        version = "1.1.0-b${llamaBuild}"; # upstream CMake reports 1.1.0 at this tag
        src = llamaSrc;
        # Upstream moved the web UI from tools/ui to ui/apps/chat after
        # v1.0.0. Building it there leaves ui/apps/chat/dist, which
        # scripts/ui-assets.cmake embeds ahead of any npm/HF-download step.
        npmRoot = "ui/apps/chat";
        preConfigure = ''
          pushd ui/apps/chat
          LLAMA_BUILD_NUMBER=${llamaBuild} LLAMA_UI_VERSION=b${llamaBuild} npm run build
          popd
        '';
        # Unavoidable hashed fetch: npm deps are not a flake input.
        npmDepsHash = "sha256-7xZK5hFUsVuhStLH+LHDaJWPwanbfkTY6pPrvuYLyLs=";
        # Informational only (--version, /props).
        cmakeFlags =
          (lib.filter (f:
            !(lib.hasPrefix "-DLLAMA_BUILD_COMMIT" f)
            && !(lib.hasPrefix "-DLLAMA_BUILD_NUMBER" f))
          old.cmakeFlags)
          ++ [
            (lib.cmakeFeature "LLAMA_BUILD_NUMBER" llamaBuild)
            (lib.cmakeFeature "LLAMA_BUILD_COMMIT" llamaCommit)
            # never try to download a prebuilt UI inside the sandbox
            (lib.cmakeBool "LLAMA_USE_PREBUILT_UI" false)
          ];
      });
  in {
    nixpkgs.overlays = [
      (final: prev: {
        # Pure Vulkan build. Needed because avalon sets
        # nixpkgs.config.rocmSupport = true (hardware-options.nix), which
        # leaks into pkgs.llama-cpp-vulkan and compiles the HIP backend in
        # too -- llama.cpp then sees the same iGPU as two devices. Disabling
        # rocmSupport also matches Hydra's cached llama-cpp-vulkan build.
        llama-cpp-vulkan-strix =
          (pinSrc (prev.llama-cpp.override {
            vulkanSupport = true;
            rocmSupport = false;
          })).overrideAttrs (old: {
            # Qwen3.8-Flash-Next (qwen4exp) MTP speculative decoding aborts at
            # load on 0.6.0-0.8.0 (ggml-org/llama.cpp#30860, open as of
            # 2026-11-04). Remove once nixpkgs ships a release with the fix.
            patches = (old.patches or []) ++ [./patches/llamacpp-qwen4exp-mtp-kpool.patch];
          });

        # Note: pkgs.llama-cpp-rocm is a thin wrapper whose .override only
        # accepts `llama-cpp`, so override the base package directly.
        llama-cpp-rocm-strix =
          (pinSrc (prev.llama-cpp.override {
            rocmSupport = true;
            rocmGpuTargets = ["gfx1151"];
          })).overrideAttrs (old: {
            cmakeFlags =
              (old.cmakeFlags or [])
              ++ [
                # rocWMMA-accelerated flash attention (large prompt-processing win)
                "-DGGML_HIP_ROCWMMA_FATTN=ON"
                # The raw HIP compiler (CMAKE_HIP_COMPILER=hipClang) bypasses the
                # cc-wrapper, so buildInputs include paths don't reach it; point
                # it at the rocWMMA headers directly. No spaces allowed here:
                # cmakeFlags is whitespace-split by the generic builder.
                "-DCMAKE_HIP_FLAGS=-I${final.rocmPackages.rocwmma}/include"
              ];
            buildInputs =
              (old.buildInputs or [])
              ++ [
                final.rocmPackages.rocwmma
                # rocBLAS can dispatch GEMMs to hipBLASLt at runtime when
                # ROCBLAS_USE_HIPBLASLT=1 is set (see llamacpp-qwen36.nix)
                final.rocmPackages.hipblaslt
              ];
          });
      })
    ];
  };
}
