{inputs, ...}: {
  flake.nixosModules.llamacpp-qwen36 = {
    pkgs,
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
      openFirewall = false;
      settings = {
        host = "127.0.0.1";
        model = "/var/lib/models/Qwen3.6-27B-Q4_K_M.gguf";
        port = 8081; # cuz glance is on 8080
        "verbose" = true;
        "log-file" = "/tmp/llama-server.log";
        "gpu-layers" = 999; # 999 = as many as possible
        "ctx-size" = 262144;
        "presence-penalty" = 0.2;
        "n-predict" = 32768; # this is output-length
        "temp" = 0.6;
        "top-p" = 0.95;
        "top-k" = 20;
        "min-p" = 0.00;
      };
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
