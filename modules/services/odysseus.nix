{inputs, ...}: {
  # Odysseus: self-hosted AI workspace (chat + agent + deep research + notes)
  # from github:odysseus-dev/odysseus (AGPL-3.0). Upstream only ships Docker
  # Compose, so this mirrors their docker-compose.yml with oci-containers:
  #   odysseus  -> host network, uvicorn bound to 127.0.0.1:7000 (so it can
  #                reach llama-server on 127.0.0.1:8081 and is NOT reachable
  #                over tailscale0, which the firewall trusts; Caddy fronts it)
  #   searxng   -> podman bridge, 127.0.0.1:8092 (upstream uses 8080 = glance)
  #   chromadb  -> podman bridge, 127.0.0.1:8100
  #   ntfy      -> podman bridge, 127.0.0.1:8091
  # LLM + embeddings come from the llama.cpp router (llamacpp-gemma.nix): the
  # "embeddinggemma-300m" preset there serves /v1/embeddings.
  #
  # EXPERIMENT: toggled per host, off by default. Known caveats:
  #   - agent/tool-calling against local llama.cpp is model dependent
  #     (odysseus-dev/odysseus#174, fixed in #759) -- test agent mode, not
  #     just chat
  #   - first boot pulls ~3 GB of images and the embedding model
  #   - Cookbook "local serve" features are irrelevant here; we already run
  #     llama-server on the host
  flake.nixosModules.odysseus = {
    pkgs,
    lib,
    config,
    ...
  }: let
    stateDir = "/var/lib/odysseus";
    # Secrets live outside git. Create this file by hand (mode 0600, root):
    #   SEARXNG_SECRET=<python -c 'import secrets;print(secrets.token_urlsafe(48))'>
    #   ODYSSEUS_ADMIN_PASSWORD=<first-boot admin password; user is "admin">
    # Optional extras, all passed straight through to the app:
    #   OPENAI_API_KEY=, HF_TOKEN=, TAVILY_API_KEY=, DATA_BRAVE_API_KEY=,
    #   GOOGLE_OAUTH_CLIENT_ID=, GOOGLE_OAUTH_CLIENT_SECRET=
    envFile = "${stateDir}/env";
    appPort = 7000;
    caddyPort = 8084; # 8083 is calibre-web
    searxngPort = 8092; # 8080 is glance, 8090 is city-explorer
    chromaPort = 8100;
    ntfyPort = 8091;
    llamaUrl = "127.0.0.1:8081";
    publicUrl = "https://${config.networking.hostName}.${config.networking.domain}:${toString caddyPort}";
    # Upstream config/searxng/settings.yml minus the secret placeholder; the
    # official searxng image reads SEARXNG_SECRET from the environment instead.
    # The json format is what Odysseus's web search actually needs.
    searxngSettings = pkgs.writeText "odysseus-searxng-settings.yml" ''
      use_default_settings: true

      server:
        bind_address: "0.0.0.0"
        port: 8080

      search:
        formats:
          - html
          - json
    '';
  in {
    systemd.tmpfiles.rules = [
      "d ${stateDir} 0750 root root -"
      # odysseus entrypoint chowns these to PUID/PGID (1000 = pwalsh)
      "d ${stateDir}/app 0755 1000 1000 -"
      "d ${stateDir}/app/data 0755 1000 1000 -"
      "d ${stateDir}/app/logs 0755 1000 1000 -"
      "d ${stateDir}/app/ssh 0700 1000 1000 -"
      "d ${stateDir}/app/huggingface 0755 1000 1000 -"
      "d ${stateDir}/app/local 0755 1000 1000 -"
      "d ${stateDir}/chroma 0755 root root -"
      "d ${stateDir}/ntfy 0755 root root -"
      "d ${stateDir}/searxng 0755 root root -"
      # copy once; searxng rewrites/owns it afterwards
      "C ${stateDir}/searxng/settings.yml 0644 - - - ${searxngSettings}"
    ];

    virtualisation.oci-containers.containers = {
      odysseus-searxng = {
        # Pinned by upstream: 2026.6.2 crashes on boot (odysseus issue #1414)
        image = "docker.io/searxng/searxng:2026.5.31-7159b8aed";
        autoStart = true;
        ports = ["127.0.0.1:${toString searxngPort}:8080"];
        volumes = ["${stateDir}/searxng:/etc/searxng"];
        environment = {
          SEARXNG_BASE_URL = "http://127.0.0.1:${toString searxngPort}/";
        };
        environmentFiles = [envFile]; # SEARXNG_SECRET
        # Same cap set as upstream compose / searxng-docker
        extraOptions = [
          "--cap-drop=ALL"
          "--cap-add=CHOWN"
          "--cap-add=SETGID"
          "--cap-add=SETUID"
          "--cap-add=DAC_OVERRIDE"
        ];
      };

      odysseus-chromadb = {
        image = "docker.io/chromadb/chroma:1.5.9";
        autoStart = true;
        ports = ["127.0.0.1:${toString chromaPort}:8000"];
        volumes = ["${stateDir}/chroma:/chroma/chroma"];
        environment.ANONYMIZED_TELEMETRY = "FALSE";
      };

      odysseus-ntfy = {
        image = "docker.io/binwiederhier/ntfy:v2.28.0";
        autoStart = true;
        cmd = ["serve"];
        ports = ["127.0.0.1:${toString ntfyPort}:80"];
        volumes = ["${stateDir}/ntfy:/var/cache/ntfy"];
        environment.NTFY_BASE_URL = "http://127.0.0.1:${toString ntfyPort}";
      };

      odysseus = {
        # ghcr publishes 1.0.2 plus 1.0.2-dev.<sha> builds; bump deliberately
        image = "ghcr.io/odysseus-dev/odysseus:1.0.2";
        autoStart = true;
        dependsOn = ["odysseus-searxng" "odysseus-chromadb" "odysseus-ntfy"];
        # Upstream CMD binds 0.0.0.0; on the host network that would expose
        # :7000 on tailscale0. Entrypoint execs "$@", so override the bind.
        cmd = ["uvicorn" "app:app" "--host" "127.0.0.1" "--port" (toString appPort)];
        extraOptions = ["--network=host"];
        volumes = [
          "${stateDir}/app/data:/app/data"
          "${stateDir}/app/logs:/app/logs"
          "${stateDir}/app/ssh:/app/.ssh"
          "${stateDir}/app/huggingface:/app/.cache/huggingface"
          "${stateDir}/app/local:/app/.local"
        ];
        environmentFiles = [envFile]; # ODYSSEUS_ADMIN_PASSWORD, API keys
        environment = {
          PUID = "1000";
          PGID = "1000";
          # LLM backends: llama.cpp router on the host. LLM_HOST takes host:port.
          LLM_HOST = llamaUrl;
          EMBEDDING_URL = "http://${llamaUrl}/v1/embeddings";
          EMBEDDING_MODEL = "embeddinggemma-300m"; # preset in llamacpp-gemma.nix
          RESEARCH_LLM_ENDPOINT = "http://${llamaUrl}/v1/chat/completions";
          # Sidecars (host network => loopback port maps above)
          SEARXNG_INSTANCE = "http://127.0.0.1:${toString searxngPort}";
          CHROMADB_HOST = "127.0.0.1";
          CHROMADB_PORT = toString chromaPort;
          NTFY_BASE_URL = "http://127.0.0.1:${toString ntfyPort}";
          DATABASE_URL = "sqlite:///./data/app.db";
          # Reachable by the whole tailnet via Caddy: keep auth on
          AUTH_ENABLED = "true";
          LOCALHOST_BYPASS = "false";
          SECURE_COOKIES = "true";
          ODYSSEUS_ADMIN_USER = "admin";
          ALLOWED_ORIGINS = publicUrl;
          OAUTH_REDIRECT_BASE_URL = publicUrl; # only matters for remote MCP OAuth
        };
      };
    };

    # Make sure the router (and its embedding preset) is up before the app
    # starts probing LLM_HOST.
    systemd.services.podman-odysseus = {
      after = ["llama-cpp.service"];
      wants = ["llama-cpp.service"];
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

        # SSE/websocket streaming passes through; Caddy forwards
        # X-Forwarded-Proto so the app issues Secure cookies.
        reverse_proxy http://127.0.0.1:${toString appPort} {
          flush_interval -1
        }
      '';
    };
  };
}
