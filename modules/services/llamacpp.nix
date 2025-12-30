{inputs, ...}: {
  flake.nixosModules.llamacpp = {
    pkgs,
    lib,
    config,
    ...
  }: let
    inherit (config.hardware) gpu;
    # Package selection based on GPU type
    # Note: acceleration option was removed - now just set the package variant
    llamacppPkg =
      if gpu == "rocm"
      then pkgs.llama-cpp-rocm
      else pkgs.llama-cpp;
  in {
    environment.systemPackages = [llamacppPkg];
    services.llama-cpp = {
      enable = true;
      host = "127.0.0.1";
      openFirewall = true;
      extraFlags = [
        "--jinja" # what is this?
        "--verbose"
        "--log-file"
        "/tmp/llama-server.log"
        "--gpu-layers" # same as -ngl
        "999" # 999 = as many as possible
        "--threads"
        "25"
        "--threads-batch"
        "25"
        "--ctx-size"
        #"65536" # could try bigger?
        "131072" #for devstral?
        "--cache-type-k"
        "q4_0"
        "--cache-type-v"
        "q4_0"
        "--batch-size"
        "2048"
        "--ubatch-size"
        "256"
        "--flash-attn"
        "on"
        "--temp"
        "0.7"
        "--min-p"
        "0.0"
        "--top-p"
        "0.80"
        "--top-k"
        "20"
        "--repeat-penalty"
        "1.05"
      ];
      #model = "/var/lib/models/Qwen3-Coder-30B-A3B-Instruct-Q8_0.gguf";
      model = "/var/lib/models/Qwen_Qwen3-30B-A3B-Instruct-2507-Q8_0.gguf";
      #model = "/var/lib/models/Devstral-Small-2507_gguf/Devstral-Small-2507-Q4_K_M.gguf";
      port = 8081; # cuz glance is on 8080
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
