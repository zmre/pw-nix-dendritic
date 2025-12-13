{
  flake.nixosModules.tailscale = {pkgs, ...}: {
    networking.domain = "savannah-basilisk.ts.net";
    services.tailscale = {
      enable = true; # p2p mesh vpn with my hosts -- does it override dnscrypt-proxy?
      permitCertUid = "caddy";
      useRoutingFeatures = "server";
      #interfaceName = "userspace-networking";
      # extraSetFlags = [
      #   "--advertise-routes 192.168.37.0/24,192.168.3.0/24"
      #   "--ssh"
      #   "--advertise-exit-node"
      #   "--operator=pwalsh"
      # ];
    };
    # services.networkd-dispatcher = {
    #   enable = true;
    #   rules."50-tailscale" = {
    #     onState = ["routable"];
    #     script = ''
    #       NETDEV="$(ip -o route get 8.8.8.8 | cut -f 5 -d \" \")" "${pkgs.ethtool}/sbin/ethtool" -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off
    #     '';
    #   };
    # };

    environment.systemPackages = with pkgs; [
      ethtool
      #networkd-dispatcher
    ];
  };
}
