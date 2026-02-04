{
  flake.nixosModules.tailscale = {pkgs, lib, config, ...}: {
    networking.domain = "savannah-basilisk.ts.net";

    services.tailscale = {
      enable = true;
      permitCertUid = "caddy";
      useRoutingFeatures = "server";
    };

    # Use nftables natively — this kernel has no iptables NAT or rpfilter
    # modules (iptable_nat, xt_rpfilter don't exist), so the iptables-nft
    # compat layer can't create NAT chains or rpfilter rules.
    networking.nftables.enable = true;

    # Tell Tailscale to use nftables directly instead of iptables wrapper
    systemd.services.tailscaled.serviceConfig.Environment = [
      "TS_DEBUG_FIREWALL_MODE=nftables"
    ];

    # Pre-load nftables expression modules during early boot.
    # kernel.modules_disabled=1 (hardened config) locks module loading
    # after boot, so these MUST be loaded by systemd-modules-load.
    boot.kernelModules = [
      "nft_nat" # NAT chain type
      "nft_masq" # masquerade (Tailscale SNAT for subnet routing)
      "nft_fib_inet" # FIB lookup (rpfilter in nftables firewall)
      "nft_ct" # conntrack state matching
      "nft_log" # logging
    ];

    # Trust the Tailscale interface and allow WireGuard UDP port
    networking.firewall.trustedInterfaces = ["tailscale0"];
    networking.firewall.allowedUDPPorts = [config.services.tailscale.port];

    # Loose reverse-path filtering via nftables fib expression
    networking.firewall.checkReversePath = "loose";
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.rp_filter" = lib.mkForce 2;
      "net.ipv4.conf.default.rp_filter" = lib.mkForce 2;
      # Ensure forwarding is fully enabled for all interfaces
      "net.ipv4.conf.all.forwarding" = lib.mkForce true;
      "net.ipv6.conf.all.forwarding" = true;
    };

    # Performance optimization for subnet routing — enable UDP GRO forwarding
    services.networkd-dispatcher = {
      enable = true;
      rules."50-tailscale" = {
        onState = ["routable"];
        script = ''
          NETDEV="$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")"
          "${pkgs.ethtool}/sbin/ethtool" -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
    };

    environment.systemPackages = with pkgs; [
      ethtool
    ];
  };
}
