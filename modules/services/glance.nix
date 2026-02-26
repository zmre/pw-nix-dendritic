{
  flake.nixosModules.glance = {config, ...}: {
    services.glance = {
      enable = true;
      settings = {
        server = {
          host = "127.0.0.1";
          port = 8080;
        };
        # TODO: media (plex, channels, books, audiobooks)
        # nextdns status, synology status
        # Add secrets so I can watch private repos and such plus github notifications
        # See: https://github.com/glanceapp/community-widgets
        pages = [
          {
            name = "Home";
            columns = [
              {
                # Left side bar
                size = "small";
                widgets = [
                  {
                    type = "clock";
                    "hour-format" = "24h";
                  }
                  {
                    type = "calendar";
                    first-day-of-week = "monday";
                  }
                  {
                    type = "server-stats";
                    servers = [
                      {
                        type = "local";
                      }
                    ];
                  }
                  {
                    type = "rss";
                    limit = 25;
                    collapse-after = 15;
                    cache = "12h";
                    feeds = [
                      {
                        url = "https://www.theregister.com/security/headlines.atom";
                        title = "The Register - Security";
                        limit = 2;
                      }
                      {
                        url = "https://www.axios.com/feeds/feed.rss";
                        title = "Axios";
                        limit = 3;
                      }

                      {
                        url = "https://feeds.arstechnica.com/arstechnica/features?t=fd5a30170b33b5e99b3698640196099d432b3301";
                        title = "Ars Technica";
                        limit = 2;
                      }
                      {
                        url = "https://www.nytimes.com/wirecutter/feed/";
                        title = "Wirecutter";
                        limit = 1;
                      }
                      {
                        url = "https://www.theregister.com/software/ai_ml/headlines.atom";
                        title = "The Register - AI";
                        limit = 2;
                      }
                      {
                        url = "https://feeds.bloomberg.com/markets/news.rss";
                        title = "Bloomberg";
                        limit = 2;
                      }
                    ];
                  }
                ];
              }

              {
                # Main center column
                size = "full";
                widgets = [
                  {
                    type = "search";
                    "search-engine" = "kagi";
                    autofocus = true;
                  }
                  {
                    type = "group";
                    collapse-after = 15;
                    cache = "12h";
                    widgets = [
                      {
                        type = "hacker-news";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "reddit";
                        subreddit = "boulder";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "reddit";
                        subreddit = "news";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "reddit";
                        subreddit = "worldnews";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "reddit";
                        subreddit = "magic";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "reddit";
                        subreddit = "coinmagic";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "reddit";
                        subreddit = "magictricksrevealed";
                        limit = 20;
                        collapse-after = 10;
                      }
                    ];
                  }
                  {
                    type = "videos";
                    collapse-after-rows = 3;
                    style = "grid-cards";
                    include-shorts = true;
                    "channels" = [
                      "UCsBjURrPoezykLs9EqgamOA" # Fireship
                      "UCHnyfMqiRRG1u-2MsSQLbXA" # Veritasium
                      "UCBJycsmduvYEL83R_U4JriQ" # Marques Brownlee
                      "UCqFzWxSCi39LnW1JKFR3efg" # SNL
                      "UCY1kMZp36IQSyNx_9h4mpCg" # Mark Rober
                      "UCQsmxaMzYr76Yd1iqMEq8TA" # Card Magic by Jason
                      "UCnCikd0s4i9KoDtaHPlK-JA" # Daniel Miessler
                    ];
                  }
                  {
                    type = "group";
                    collapse-after = 15;
                    cache = "12h";
                    widgets = [
                      {
                        type = "reddit";
                        subreddit = "neovim";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "reddit";
                        subreddit = "apple";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "reddit";
                        subreddit = "nixos";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "reddit";
                        subreddit = "selfhosted";
                        limit = 20;
                        collapse-after = 10;
                      }
                      {
                        type = "reddit";
                        subreddit = "commandline";
                        limit = 20;
                        collapse-after = 10;
                      }
                    ];
                  }
                ];
              }

              {
                # Right side bar
                size = "small";
                widgets = [
                  {
                    type = "weather";
                    location = "Boulder, Colorado, USA";
                    units = "imperial";
                    "hour-format" = "24h"; # alternatively "24h"
                    # Optionally hide the location from being displayed in the widget
                    # hide-location= true
                  }
                  {
                    type = "bookmarks";
                    groups = [
                      {
                        links = [
                          {
                            title = "Plex";
                            url = "https://${config.networking.hostName}.${config.networking.domain}:32400/";
                          }
                          {
                            title = "Channels";
                            url = "http://synology1.${config.networking.domain}:8089/";
                          }
                          #{title="Jellyfin"; url="https://${config.networking.hostName}${config.networking.domain}:8096/";}
                          {
                            title = "Magic";
                            url = "https://synology1.${config.networking.domain}/magic/";
                          }
                          {
                            title = "AudioBookShelf";
                            url = "https://avalon.${config.networking.domain}:8000/";
                          }
                          {
                            title = "Calibre";
                            url = "https://avalon.${config.networking.domain}:8083/";
                          }
                          {
                            title = "MBR Magic";
                            url = "https://avalon.${config.networking.domain}:5201/";
                          }
                          {
                            title = "City Livability Explorer";
                            url = "https://avalon.${config.networking.domain}:8090/";
                          }
                          {
                            title = "Synology Admin";
                            url = "http://synology1.${config.networking.domain}:5000/";
                          }
                          {
                            title = "HDHomeRun";
                            url = "http://192.168.37.12/lineup.html";
                          }
                        ];
                      }
                    ];
                  }
                  {
                    type = "markets";
                    markets = [
                      {
                        symbol = "DJI";
                        name = "Dow Jones";
                      }
                      {
                        symbol = "SPY";
                        name = "S&P 500";
                      }
                      {
                        symbol = "IXIC";
                        name = "Nasdaq";
                      }
                      {
                        symbol = "AAPL";
                        name = "Apple";
                      }
                      {
                        symbol = "AMZN";
                        name = "Amazon";
                      }
                      {
                        symbol = "BRK-A";
                        name = "Berkshire";
                      }
                      {
                        symbol = "GOOG";
                        name = "Google";
                      }
                      {
                        symbol = "NVDA";
                        name = "Nvidia";
                      }
                    ];
                  }
                ];
              }
            ];
          }
          {
            name = "Dev";
            columns = [
              {
                # Left side bar
                size = "small";
                widgets = [
                  {
                    type = "monitor";
                    cache = "1m";
                    sites = [
                      {
                        title = "IronCore Website";
                        url = "https://ironcorelabs.com/";
                      }
                      {
                        title = "IronCore CB";
                        url = "https://config.ironcorelabs.com/";
                      }
                      # {
                      #   title = "Plex";
                      #   url = "https://${config.networking.hostName}.${config.networking.domain}:32400/";
                      # }
                      {
                        title = "Synology1";
                        url = "https://synology1.${config.networking.domain}/";
                      }
                    ];
                  }
                  # {type = "docker-containers";}
                ];
              }
              {
                # Main section
                size = "full";
                widgets = [
                  {
                    type = "repository";
                    repository = "zmre/pw-nix-dendritic";
                    cache = "12h";
                  }
                  {
                    type = "repository";
                    repository = "zmre/mbr-markdown-browser";
                    cache = "12h";
                  }
                  {
                    type = "repository";
                    repository = "zmre/nix-pai";
                    cache = "12h";
                  }
                  {
                    type = "repository";
                    repository = "zmre/pwnvim";
                    cache = "12h";
                  }
                  {
                    type = "repository";
                    repository = "zmre/mdenhance";
                    cache = "12h";
                  }
                  {
                    type = "repository";
                    repository = "zmre/pwdev";
                    cache = "12h";
                  }

                  {
                    type = "repository";
                    repository = "ironcorelabs/recrypt-rs";
                    cache = "12h";
                  }
                  {
                    type = "repository";
                    repository = "ironcorelabs/ironcore-alloy";
                    cache = "12h";
                  }
                  {
                    type = "repository";
                    repository = "ironcorelabs/gridiron";
                    cache = "12h";
                  }
                  # {
                  #   type = "repository";
                  #   repository = "ironcorelabs/website";
                  #   cache = "12h";
                  # }
                ];
              }
            ];
          }
        ];
      };
    };

    networking.firewall.allowedTCPPorts = [443];
    services.caddy.virtualHosts."${config.networking.hostName}.${config.networking.domain}:443" = {
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
        reverse_proxy http://127.0.0.1:8080
      '';
    };
  };
}
