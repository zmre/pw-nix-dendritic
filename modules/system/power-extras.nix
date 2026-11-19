{
  # Declares `powerExtras.enable`, a flag for gating "power user" apps that
  # not every Mac needs (pro media tools, niche utilities, alt browsers, etc.).
  # Lives in the shared `system` darwin module so every darwin host has it.
  # Defaults to true so existing hosts are unchanged; lighter hosts set false.
  #
  # Usage in another darwin module:
  #   homebrew.casks = ["always"] ++ lib.optionals config.powerExtras.enable ["extra"];
  flake.darwinModules.system = {lib, ...}: {
    options.powerExtras.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install power-user extra apps (casks, mas apps, brews) gated behind this flag.";
    };
  };
}
