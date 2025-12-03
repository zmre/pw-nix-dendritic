{config, ...}: {
  # Configuration for using remote builders on Darwin
  flake.darwinModules.remote-builders = {
    pkgs,
    lib,
    ...
  }: {
    # Only evaluate on Darwin systems
    nix.buildMachines = [
      {
        hostName = "avalon";
        # The architectures this builder can build for
        systems = ["x86_64-linux" "aarch64-linux"];

        # Adjust based on avalon's CPU cores
        maxJobs = 8;

        # Optional: relative speed compared to local building
        speedFactor = 2;

        # Features the remote builder supports
        supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];

        # Features that MUST be present for this builder to be used
        mandatoryFeatures = [];
      }
    ];

    # Enable distributed builds
    nix.distributedBuilds = true;

    # Prefer remote builders for Linux builds
    nix.settings = {
      # Allow builders to use binary caches instead of building everything
      builders-use-substitutes = true;
    };
  };
}
