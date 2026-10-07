{inputs, ...}: {
  flake.nixosModules.llamacpp-gemma = {
    pkgs,
    config,
    ...
  }: let
    inherit (config.hardware) gpu;
    backend = "vulkan";
    llamacppPkg =
      if gpu != "rocm"
      then pkgs.llama-cpp
      else if backend == "vulkan"
      then pkgs.llama-cpp-vulkan-strix
      else pkgs.llama-cpp-rocm-strix;
  in {
    environment.systemPackages = [llamacppPkg];
    services.llama-cpp = {
      enable = true;
      package = llamacppPkg;
      openFirewall = false;
      settings = {
        host = "127.0.0.1";
        port = 8081; # cuz glance is on 8080
        "verbose" = true;
        "log-file" = "/tmp/llama-server.log";
        models-preset = (pkgs.formats.ini {}).generate "models-preset.ini" {
          # note some other ways to specify models and names:
          #           hf-repo = "unsloth/Qwen3-Coder-Next-GGUF";
          #           hf-file = "Qwen3-Coder-Next-UD-Q4_K_XL.gguf";
          #           alias = "unsloth/Qwen3-Coder-Next";
          "gemma4-26b-a4b-q8" = {
            model = "/var/lib/models/gemma-4-26B-A4B-it-Q8_0.gguf";
            alias = "gemma4-26b-a4b-q8";
            "gpu-layers" = 999; # 999 = as many as possible
            "ctx-size" = 262144;
            "load-mode" = "none"; # was no-mmap (removed upstream); mmap'd pages kill ROCm perf on Strix Halo (2X+)
            "flash-attn" = "on"; # explicit; auto already enables it but be sure
            "batch-size" = 512;
            "ubatch-size" = 512;
          };
          "gemma4-26b-a4b-q4-summaries" = {
            hf-repo = "unsloth/gemma-4-26B-A4B-it-GGUF";
            hf-file = "gemma-4-26B-A4B-it-UD-Q4_K_M.gguf";
            "gpu-layers" = 999; # 999 = as many as possible
            "reasoning" = "off";
            "ctx-size" = 65536;
            "load-mode" = "none"; # was no-mmap (removed upstream); mmap'd pages kill ROCm perf on Strix Halo (2X+)
            "flash-attn" = "on"; # explicit; auto already enables it but be sure
            "batch-size" = 512;
            "ubatch-size" = 512;
            "n-predict" = 1024; # bound output; default -1 is unbounded
            "cache-type-k" = "q8_0";
            "cache-type-v" = "q8_0";
            "temp" = 0.7; # Gemma 4's baked-in default is 1.0
            "top-k" = 40;
            "top-p" = 0.95;
            "min-p" = 0.05;
            "repeat-penalty" = 1.05;
          };
          "qwen36-27b-q4" = {
            model = "/var/lib/models/Qwen3.6-27B-Q4_K_M.gguf";
            "gpu-layers" = 999; # 999 = as many as possible
            "ctx-size" = 262144;
            "load-mode" = "none"; # was no-mmap (removed upstream); mmap'd pages kill ROCm perf on Strix Halo (2X+)
            "flash-attn" = "on"; # explicit; auto already enables it but be sure
            "batch-size" = 512;
            "ubatch-size" = 512;
            # Halve the 16 GiB KV cache at full context if memory gets tight:
            #"cache-type-k" = "q8_0";
            #"cache-type-v" = "q8_0";
            "presence-penalty" = 0.2;
            "n-predict" = 32768; # this is output-length
            "temp" = 0.6;
            "top-p" = 0.95;
            "top-k" = 20;
            "min-p" = 0.00;
          };
          "qwen36-35b-a3b-q4" = {
            hf-repo = "unsloth/Qwen3.6-35B-A3B-GGUF";
            hf-file = "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
            "gpu-layers" = 999; # 999 = as many as possible
            "ctx-size" = 262144;
            "load-mode" = "none"; # was no-mmap (removed upstream); mmap'd pages kill ROCm perf on Strix Halo (2X+)
            "flash-attn" = "on"; # explicit; auto already enables it but be sure
            "batch-size" = 512;
            "ubatch-size" = 512;
            # Halve the 16 GiB KV cache at full context if memory gets tight:
            #"cache-type-k" = "q8_0";
            #"cache-type-v" = "q8_0";
            "presence-penalty" = 0.2;
            "n-predict" = 32768; # this is output-length
            "temp" = 0.6;
            "top-p" = 0.95;
            "top-k" = 20;
            "min-p" = 0.00;
          };
          "qwen38-27b-q8" = {
            hf-repo = "unsloth/Qwen3.8-27B-GGUF";
            hf-file = "Qwen3.8-27B-Q8_0.gguf";
            "gpu-layers" = 999; # 999 = as many as possible
            "ctx-size" = 262144;
            "load-mode" = "none"; # was no-mmap (removed upstream); mmap'd pages kill ROCm perf on Strix Halo (2X+)
            "flash-attn" = "on"; # explicit; auto already enables it but be sure
            "batch-size" = 512;
            "ubatch-size" = 512;
            # Halve the 16 GiB KV cache at full context if memory gets tight:
            #"cache-type-k" = "q8_0";
            #"cache-type-v" = "q8_0";
            "presence-penalty" = 0.0;
            #"repetition-penalty" = 1.0;
            "n-predict" = 32768; # this is output-length
            "temp" = 1.0;
            "top-p" = 0.95;
            "top-k" = 20;
            "min-p" = 0.00;
          };
          "qwen38-27b-q4" = {
            hf-repo = "unsloth/Qwen3.8-27B-GGUF";
            hf-file = "Qwen3.8-27B-Q4_0.gguf";
            "gpu-layers" = 999; # 999 = as many as possible
            "ctx-size" = 262144;
            "load-mode" = "none"; # was no-mmap (removed upstream); mmap'd pages kill ROCm perf on Strix Halo (2X+)
            "flash-attn" = "on"; # explicit; auto already enables it but be sure
            "batch-size" = 512;
            "ubatch-size" = 512;
            # Halve the 16 GiB KV cache at full context if memory gets tight:
            #"cache-type-k" = "q8_0";
            #"cache-type-v" = "q8_0";
            "presence-penalty" = 0.0;
            #"repetition-penalty" = 1.0;
            "n-predict" = 32768; # this is output-length
            "temp" = 1.0;
            "top-p" = 0.95;
            "top-k" = 20;
            "min-p" = 0.00;
          };
          # Qwen3.8-Flash-Next (qwen4exp arch: 512-expert MoE, 10 active, Gated
          # DeltaNet hybrid attention, n-gram embedding table). ISTA-DASLab's
          # GSQ-RCO non-uniform quant; IQ3_S is their recommended tier (matches
          # or beats the base model on their evals). Two shards: 00001 = weights
          # (54.8 GB), 00002 = the 51B-param n-gram table (28.8 GB). llama.cpp
          # fetches the second shard automatically.
          # https://huggingface.co/ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-GGUF
          "qwen38-flash-next-gsq-iq3s" = {
            hf-repo = "ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-GGUF";
            hf-file = "IQ3_S/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_S-00001-of-00002.gguf";
            "gpu-layers" = 999; # 999 = as many as possible
            "ctx-size" = 262144; # hybrid DeltaNet => KV cache stays small at full ctx
            # Deviates from the other presets on purpose: the repo README says to
            # keep the n-gram shard mmap'd and read on demand (-lm mmap
            # --lazy-mode on) instead of pulling all 83.6 GB resident. Benchmark
            # "none" vs "mmap" here if tg feels slow.
            "load-mode" = "mmap";
            "lazy-mode" = "on";
            "flash-attn" = "on";
            "batch-size" = 1024;
            "ubatch-size" = 512;
            "n-predict" = 32768; # this is output-length
            # Qwen's thinking-mode sampling (unsloth docs); non-thinking is
            # temp 0.7 / top-p 0.8 / presence 1.5
            "temp" = 1.0;
            "top-p" = 0.95;
            "top-k" = 20;
            "min-p" = 0.00;
            "presence-penalty" = 0.0;
          };
          # Tiny embedding model so the router answers /v1/embeddings
          # (used by odysseus.nix for RAG/memory). ~300 MB, 768-dim, 2k ctx.
          "embeddinggemma-300m" = {
            hf-repo = "ggml-org/embeddinggemma-300M-GGUF";
            hf-file = "embeddinggemma-300M-Q8_0.gguf";
            "embedding" = true;
            "gpu-layers" = 999;
            "ctx-size" = 2048; # model max
            "batch-size" = 2048;
            "ubatch-size" = 2048; # must be >= ctx for non-causal embedding
            "load-mode" = "none";
          };
        };
        # Halve the 16 GiB KV cache at full context if memory gets tight:
        #"cache-type-k" = "q8_0";
        #"cache-type-v" = "q8_0";
        #"presence-penalty" = 0.2;
        #"n-predict" = 32768; # this is output-length
        #"temp" = 0.6;
        #"top-p" = 0.95;
        #"top-k" = 20;
        #"min-p" = 0.00;
      };
    };
    systemd.services.llama-cpp.environment =
      if backend == "vulkan"
      then {
        # RADV beats AMDVLK on Strix Halo, and AMDVLK's 2GB buffer limit
        # breaks 30B+ models
        AMD_VULKAN_ICD = "RADV";
      }
      else {
        # Dispatch rocBLAS GEMMs to hipBLASLt (gfx1151 kernels need ROCm 7.2+)
        ROCBLAS_USE_HIPBLASLT = "1";
        # Kernel 6.18 detects gfx1151 natively -- do NOT add
        # HSA_OVERRIDE_GFX_VERSION here. Trap: 6.19.x misdetects the GPU as
        # gfx1100 and needs HSA_OVERRIDE_GFX_VERSION=11.5.1 again.
      };
    networking.firewall.allowedTCPPorts = [8082];
    services.caddy.virtualHosts."${config.networking.hostName}.${config.networking.domain}:8082" = {
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

        reverse_proxy http://127.0.0.1:8081 {
          header_up Host {upstream_hostport}
        }
      '';
    };
  };
}
