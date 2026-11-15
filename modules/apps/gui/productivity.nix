{inputs, ...}: {
  # Contacts2MdSync: two-way Apple Contacts <-> markdown notes sync (SwiftUI,
  # macOS only). Upstream ships a nix-darwin module that adds its overlay and
  # installs the app into /Applications/Nix Apps.
  flake-file.inputs.contacts2mdsync = {
    url = "github:zmre/contacts2mdsync";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.darwinModules.productivity-gui = {pkgs, ...}: {
    imports = [inputs.contacts2mdsync.darwinModules.default];

    programs.contacts2mdsync = {
      enable = true;
      # Pin the Developer ID signed, notarized GitHub release (pure, no Xcode,
      # stable code identity so Contacts/Automation grants and the chosen notes
      # folder survive rebuilds). Upstream's default silently falls back to the
      # impure ad-hoc from-source build if no release exists; pinning makes that
      # an eval error instead.
      package = pkgs.contacts2mdsync-release;
      # Hourly headless `sync --quiet` via launchd. Requires first opening the
      # app, granting Contacts access, choosing the notes folder, and running
      # one sync. Upstream still marks launchd runs as untested (spike S11).
      schedule.enable = false;
    };
  };
}
