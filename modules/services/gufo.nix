{inputs, ...}: {
  # Gufo: a standalone inference engine purpose-built for Strix Halo (gfx1151).
  # https://github.com/gufo-org/gufo -- MIT, C++/HIP, OpenAI-compatible API.
  # Experiment: compare its prefill/decode against llama-server on the same
  # Qwen3.8-Flash-Next weights. Upstream claims ~1600 tok/s pp vs ~300-370
  # for a llama.cpp Vulkan build on this hardware.
  #
  # Measured on avalon 2026-10-04 (Unsloth UD-Q4_K_XL, single stream, greedy,
  # thinking off, median of 3; full tables in ~/bench/RESULTS.md):
  #   llama.cpp master c061df1 Vulkan: pp2048 445 t/s | pp8k 454 | tg 24.4
  #   gufo 23cacbb AR:                 pp2048 1228    | pp8k 1260 | tg 25.1
  #   gufo + MTP shared-Q8_0 head:     pp2048 1202    | pp8k 1224 | tg 33-47
  #   (MTP tg depends on draft acceptance: 58% on prose, 79% on repetitive text)
  # Gufo loads in ~15 s vs ~170 s for llama.cpp Vulkan. Gufo refuses the ISTA
  # GSQ-RCO IQ3_S files ("unsupported storage type" on ffn_gate_exps).
  #
  # MEMORY CONTENTION -- enable EITHER this module OR a llamacpp-* module on a
  # host, never both at once. The UD-Q4_K_XL target is ~111 GB resident on a
  # 128 GB box; a loaded llama-server model alongside it will OOM one of them.
  # Deliberately no Conflicts= against llama-cpp.service: silently stopping the
  # router would be surprising. Toggle via the host's wantedModules instead.
  #
  # Upstream Nix facts (checked 2026-10-02, main @ v0.5.0):
  #   - flake exports packages.<sys>.default (the `gufo` binary) and
  #     lib.mkGufoServe (builds the `gufo serve ...` command line). No
  #     nixosModules, so the systemd unit lives here.
  #   - Qwen3.8-Flash-Next support is qualified ONLY against
  #     unsloth/Qwen3.8-Flash-Next-GGUF UD-Q4_K_XL (four shards) plus the
  #     optional shared-Q8 MTP head and mmproj-BF16. The ISTA-DASLab GSQ-RCO
  #     IQ3_S quant used by the llama.cpp router is NOT listed as supported.
  #   - Flash-Next MTP speculative decoding IS supported in HTTP serving
  #     (--speculative mtp --mtp-model ...), unlike mainline llama.cpp today.
  #   - Upstream pins an older nixpkgs than ours; we `follows` ours so
  #     rocmPackages come from a single nixpkgs. If the HIP build breaks after
  #     a nixpkgs bump, first try dropping the follows (upstream qualifies
  #     GCC 15.3 + ROCm 7.2.3).
  #
  # One-time model download (not managed by Nix; ~111 GB + 2.8 GB MTP + 0.9 GB
  # mmproj; revision pinned by upstream's model guide):
  #
  #   sudo nix shell nixpkgs#python3Packages.huggingface-hub -c hf download \
  #     unsloth/Qwen3.8-Flash-Next-GGUF \
  #     --revision 38bb39ee97821de2c9009abb7e93950eec396e66 \
  #     --include "UD-Q4_K_XL/*" "MTP/mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf" "mmproj-BF16.gguf" \
  #     --local-dir /var/lib/models/qwen3.8-flash-next
  #
  # Smoke test after switch:
  #   gufo diagnose
  #   curl https://avalon.<tailnet>:8086/v1/models
  flake-file.inputs.gufo = {
    url = "github:gufo-org/gufo";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.nixosModules.gufo = {
    pkgs,
    lib,
    config,
    ...
  }: let
    system = pkgs.stdenv.hostPlatform.system;
    gufoPkg = inputs.gufo.packages.${system}.default;

    # Gufo listens here (loopback only); Caddy terminates TLS on externalPort.
    gufoPort = 8085;
    externalPort = 8086;

    modelDir = "/var/lib/models/qwen3.8-flash-next";
    # First shard; the loader discovers the rest.
    model = "${modelDir}/UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf";
    mtpModel = "${modelDir}/MTP/mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf";

    # Builds: gufo serve --host 127.0.0.1 --port 8085 --sessions 2 llm
    #   --model <shard1> --served-model-name qwen38-flash-next --context 262144
    #   --speculative mtp --mtp-model <mtp> --think auto
    # Sampling is left to Gufo's built-in Qwen defaults (thinking: temp 1.0,
    # top-p 0.95, top-k 20; thinking off: 0.7 / 0.8 / 20 / presence 1.5),
    # which match what the llama.cpp preset uses.
    serveCmd = inputs.gufo.lib.mkGufoServe {
      inherit system;
      gufo = gufoPkg;
      host = "127.0.0.1";
      port = gufoPort;
      # Preallocated GPU request sessions (= concurrent generations; extra
      # requests queue). Measured 2026-10-05 at context 262144 + MTP:
      #   1 session: 101 GB GPU, single-stream tg 34.5 t/s
      #   2 sessions: 101 GB GPU, ~18 GB host headroom, single-stream tg 31.3
      # 2 so an agent making parallel calls is not serialised; drop to 1 if
      # memory gets tight or single-stream speed matters more.
      sessions = 2;
      modality = "llm";
      inherit model;
      servedModelName = "qwen38-flash-next";
      # Per-session context capacity, reserved up front. Native 262144 loads
      # fine on avalon with 1 session + MTP (tested 2026-10-05, same pp/tg as
      # at 32768), so use it; drop back to 32768 if sessions are raised and
      # memory gets tight.
      context = 262144;
      speculative = "mtp";
      inherit mtpModel;
      think = "auto";
    };
  in {
    environment.systemPackages = [gufoPkg];

    systemd.services.gufo = {
      description = "Gufo inference engine (OpenAI-compatible, Strix Halo)";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      # Refuse to start without the weights rather than crash-loop.
      unitConfig.ConditionPathExists = model;
      environment = {
        # ROCm/HIP and comgr write kernel caches under $HOME/.cache; give the
        # dynamic user a real one (llama-server logs "Failed to create //.cache"
        # for the same reason).
        HOME = "/var/cache/gufo";
        XDG_CACHE_HOME = "/var/cache/gufo";
        # Kernel 6.18 detects gfx1151 natively -- do NOT set
        # HSA_OVERRIDE_GFX_VERSION here (see llamacpp-qwen36.nix).
      };
      serviceConfig = {
        ExecStart = serveCmd;
        Restart = "on-failure";
        RestartSec = 30;

        DynamicUser = true;
        SupplementaryGroups = ["render" "video"];
        CacheDirectory = "gufo";
        StateDirectory = "gufo";
        WorkingDirectory = "/var/lib/gufo";
        # Upstream runs the container with --ulimit memlock=-1.
        LimitMEMLOCK = "infinity";

        # Hardening, modelled on the nixpkgs llama-cpp unit but relaxed where
        # HIP needs it: the GPU nodes must be visible, and HIP's runtime
        # compiler needs W+X mappings.
        PrivateDevices = false;
        DevicePolicy = "closed";
        DeviceAllow = [
          "/dev/kfd rw"
          "char-drm rw" # /dev/dri/renderD* and card*
        ];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
        LockPersonality = true;
        SystemCallArchitectures = "native";
      };
    };

    networking.firewall.allowedTCPPorts = [externalPort];

    services.caddy.virtualHosts."${config.networking.hostName}.${config.networking.domain}:${toString externalPort}" = {
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

        reverse_proxy http://127.0.0.1:${toString gufoPort} {
          header_up Host {upstream_hostport}
        }
      '';
    };
  };
}
