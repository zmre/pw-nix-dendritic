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
  flake.nixosModules.llamacpp-packages = {
    nixpkgs.overlays = [
      (final: prev: {
        # Pure Vulkan build. Needed because avalon sets
        # nixpkgs.config.rocmSupport = true (hardware-options.nix), which
        # leaks into pkgs.llama-cpp-vulkan and compiles the HIP backend in
        # too -- llama.cpp then sees the same iGPU as two devices. Disabling
        # rocmSupport also matches Hydra's cached llama-cpp-vulkan build.
        llama-cpp-vulkan-strix = prev.llama-cpp.override {
          vulkanSupport = true;
          rocmSupport = false;
        };

        # Note: pkgs.llama-cpp-rocm is a thin wrapper whose .override only
        # accepts `llama-cpp`, so override the base package directly.
        llama-cpp-rocm-strix =
          (prev.llama-cpp.override {
            rocmSupport = true;
            rocmGpuTargets = ["gfx1151"];
          }).overrideAttrs (old: {
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
