{
  flake.nixosModules.search = {...}: {
    services.meilisearch = {
      enable = true;
      masterKeyFile = "/etc/meilisearch-key";
      listenAddress = "0.0.0.0";
      settings = {
        # # we use `listenAddress` and `listenPort` to derive the `http_addr` setting.
        # # this is the only setting we treat like this.
        # # we do this because some dependent services like Misskey/Sharkey need separate host,port for no good reason.
        # #http_addr = "${cfg.listenAddress}:${toString cfg.listenPort}";
        # http_addr = "localhost:7700";

        # upstream's default for `db_path` is `/var/lib/meilisearch/data.ms/`, but ours is different for no reason.
        db_path = "/var/lib/meilisearch";
        # these are equivalent to the upstream defaults, because we set a working directory.
        # they are only set here for consistency with `db_path`.
        dump_dir = "/var/lib/meilisearch/dumps";
        snapshot_dir = "/var/lib/meilisearch/snapshots";

        # this is intentionally different from upstream's default.
        no_analytics = true;
      };
    };
  };
}
