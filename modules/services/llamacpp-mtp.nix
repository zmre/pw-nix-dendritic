{inputs, ...}: {
  # EXPERIMENT: Qwen3.8-Flash-Next with Multi-Token-Prediction speculative
  # decoding, served by a second llama-server built from llama.cpp master.
  #
  # Why a separate build: nixpkgs llama-cpp 0.5.0 (build 11146, tag v0.5.0)
  # knows the qwen4exp arch but predates "Qwen4Exp: add MTP" (ggml-org PR
  # #29761, merged 2026-10-01, commit c061df1). Upstream measured ~1.5x decode
  # on a DGX Spark with that PR (see the PR description). The earlier PR
  # #28243 was superseded by #29761, so no fork is needed; we pin master at
  # the merge commit. Bump: edit the url below, `nix run .#write-flake`,
  # then recompute npmDepsHash if tools/ui/package-lock.json changed.
  #
  # MEMORY CONTENTION: this unit loads the full ~84 GB model plus a 4 GB MTP
  # head. Enable only ONE of llamacpp-gemma (the stock router on 8081),
  # llamacpp-mtp (this, 8087) or gufo at a time on avalon.
  #
  # What to benchmark once it is up (same prompt, -np 1):
  #   1. this unit as configured (tg t/s with MTP)
  #   2. same unit with `spec-type`, `spec-draft-hf`, `spec-draft-model`
  #      removed (tg t/s without MTP, same build)
  #   3. the stock router's qwen38-flash-next-gsq-iq3s preset
  # Also watch the "accept" rate in the verbose log; upstream saw ~0.6-0.7.
  # The Unsloth MTP README says MTP HURTS at concurrency >= 8 (0.81-0.87x),
  # so keep this a single-stream endpoint.
  #
  # STATUS 2026-10-04: DOES NOT WORK YET on this Vulkan build. Tested manually
  # on avalon with both the ISTA IQ3_S and the Unsloth UD-Q4_K_XL main model:
  # every MTP variant (--parallel 1, --lazy-mode off, -fa off, n-max 1..3)
  # aborts at load with
  #   ggml-backend.cpp:205: GGML_ASSERT(buffer) failed
  # inside llama_model_qwen4exp::llm_graph_input_kpool::set_input ->
  # llama_kv_cache::set_input_k_idxs, during the load-time test decode in
  # common_context_can_seq_rm. The "shared" head variant cannot load on
  # mainline at all (token_embd.weight not found). Upstream only validated on
  # CUDA. Same build WITHOUT MTP works and matches 0.5.0 (pp ~450 / tg ~24.4
  # on UD-Q4_K_XL). Next things to try: the rocm-strix (HIP) build instead of
  # Vulkan, or a newer master once a Vulkan fix lands. Gufo's MTP works today
  # (see gufo.nix). Full numbers: ~/bench/RESULTS.md.
  flake-file.inputs.llama-cpp-mtp-src = {
    url = "github:ggml-org/llama.cpp/c061df19838ff60970faf54fd7e414953590125d";
    flake = false;
  };

  flake.nixosModules.llamacpp-mtp = {
    pkgs,
    lib,
    config,
    ...
  }: let
    src = inputs.llama-cpp-mtp-src;
    shortRev = builtins.substring 0 7 src.rev;

    # Pure Vulkan/RADV build, same reasoning as llamacpp-packages.nix: the
    # host's rocmSupport=true would otherwise compile HIP in as well and the
    # iGPU shows up twice. overrideAttrs re-runs the finalAttrs fixpoint, so
    # the derivation's own fetchNpmDeps picks up the new src and hash.
    llamaMtp =
      (pkgs.llama-cpp.override {
        vulkanSupport = true;
        rocmSupport = false;
      }).overrideAttrs (final: prev: {
        pname = "llama-cpp-mtp";
        version = "0.5.0-mtp-${shortRev}";
        inherit src;
        # tools/ui/package-lock.json differs from v0.5.0 (tailwind-variants
        # 3.2.2 -> 3.3.1), so the npm deps FOD needs its own hash. Unavoidable
        # hashed fetch: npm deps are not a flake input. To recompute: set to
        # lib.fakeHash, build, paste the "got:" value.
        npmDepsHash = "sha256-a17M+L3nLdRnN6WMB6imPFmwqG2g8uv+gwN0XTAUrf8=";
        # Build number/commit are informational only (--version, /props).
        # Keep nixpkgs' build number, fix the commit to what we actually built.
        cmakeFlags =
          (lib.filter (f: !(lib.hasPrefix "-DLLAMA_BUILD_COMMIT" f)) prev.cmakeFlags)
          ++ [(lib.cmakeFeature "LLAMA_BUILD_COMMIT" shortRev)];
      });

    port = 8087;
    caddyPort = 8088;

    settings = {
      host = "127.0.0.1";
      inherit port;
      verbose = true;
      "log-file" = "/tmp/llama-server-mtp.log";
      alias = "qwen38-flash-next-mtp";

      # Main model: ISTA-DASLab GSQ-RCO IQ3_S, same files the stock router
      # uses (own cache dir though, so it is downloaded a second time; ~84 GB).
      "hf-repo" = "ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-GGUF";
      "hf-file" = "IQ3_S/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_S-00001-of-00002.gguf";
      # Alternative main model if the head refuses to pair with the GSQ quant:
      #"hf-repo" = "unsloth/Qwen3.8-Flash-Next-GGUF";
      #"hf-file" = "UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf";

      # MTP draft head. The non-"shared" file carries the MTP block plus its
      # own embeddings and LM head, which is the layout mainline's loader
      # describes ("an MTP-only file carries the MTP block, the embeddings and
      # the LM head"). The "shared" variant (2.8 GB) borrows embeddings from
      # the main model; try it second.
      "spec-draft-hf" = "unsloth/Qwen3.8-Flash-Next-GGUF";
      "spec-draft-model" = "MTP/mtp-Qwen3.8-Flash-Next-Q8_0.gguf";
      #"spec-draft-model" = "MTP/mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf";
      "spec-type" = "draft-mtp";
      "spec-draft-n-max" = 2; # Unsloth's recommended default; upstream bench used 3
      parallel = 1; # MTP degrades under concurrency

      "gpu-layers" = 999;
      "ctx-size" = 262144;
      "flash-attn" = "on";
      "load-mode" = "mmap";
      "lazy-mode" = "on"; # n-gram shard read on demand
      "batch-size" = 1024;
      "ubatch-size" = 512;
      "n-predict" = 32768;
      # Qwen thinking-mode sampling
      temp = 1.0;
      "top-p" = 0.95;
      "top-k" = 20;
      "min-p" = 0.0;
      "presence-penalty" = 0.0;
    };

    # Same flag rendering the stock services.llama-cpp module uses.
    args =
      lib.cli.toCommandLine (optionName: {
        option =
          if lib.hasPrefix "-" optionName
          then optionName
          else if builtins.stringLength optionName > 1
          then "--${optionName}"
          else "-${optionName}";
        sep = " ";
        explicitBool = false;
        formatArg = lib.generators.mkValueStringDefault {};
      })
      settings;
  in {
    systemd.services.llama-cpp-mtp = {
      description = "llama.cpp (master, MTP) server for Qwen3.8-Flash-Next";
      wants = ["network.target"];
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        LLAMA_CACHE = "/var/cache/llama-cpp-mtp";
        AMD_VULKAN_ICD = "RADV"; # see llamacpp-qwen36.nix
      };
      serviceConfig = {
        ExecStart = toString ([(lib.getExe' llamaMtp "llama-server")] ++ [args]);
        ExecReload = "${lib.getExe' pkgs.coreutils "kill"} -HUP $MAINPID";
        Restart = "on-failure";
        RestartSec = 300;

        # Hardening copied from nixpkgs' services.llama-cpp unit.
        DynamicUser = true;
        StateDirectory = "llama-cpp-mtp";
        CacheDirectory = "llama-cpp-mtp";
        WorkingDirectory = "/var/lib/llama-cpp-mtp";

        AmbientCapabilities = [""];
        CapabilityBoundingSet = [""];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = false; # GPU
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = ["@system-service" "~@privileged"];
      };
    };

    networking.firewall.allowedTCPPorts = [caddyPort];
    services.caddy.virtualHosts."${config.networking.hostName}.${config.networking.domain}:${toString caddyPort}" = {
      listenAddresses = ["0.0.0.0"];
      extraConfig = ''
        tls {
          get_certificate tailscale
        }
        encode {
          zstd
          gzip
          minimum_length 1024
        }

        reverse_proxy http://127.0.0.1:${toString port} {
          header_up Host {upstream_hostport}
        }
      '';
    };
  };
}
