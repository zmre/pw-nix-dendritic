{
  flake.nixosModules.hacking = {
    pkgs,
    lib,
    config,
    ...
  }: {
    programs.wireshark.enable = true;
  };
}
