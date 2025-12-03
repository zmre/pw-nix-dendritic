{
  # This crazy modules is here so we can post-process recorded TV shows and then
  # mark the commercials (as chapters) so they can be skipped. We could cut them
  # but I don't know how good of a job it does.
  flake.nixosModules.audnexus = {
    pkgs,
    lib,
    ...
  }: let
    # Make the plugin fetch lazy - only evaluated when this config is actually merged
    audnexusPluginPath = pkgs.fetchFromGitHub {
      owner = "djdembeck";
      repo = "Audnexus.bundle";
      rev = "v1.3.2";
      sha256 = "sha256-BpwyedIjkXS+bHBsIeCpSoChyWCX5A38ywe71qo3tEI=";
    };
  in {
    options = {
    };
    config = {
      audnexusPlugin =
        if pkgs.stdenv.isLinux
        then
          builtins.path {
            name = "Audnexus.bundle";
            path = audnexusPluginPath;
          }
        else null;
    };
  };
}
