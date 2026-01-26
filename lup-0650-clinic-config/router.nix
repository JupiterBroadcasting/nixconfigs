{
  config,
  lib,
  pkgs,
  ...
}: {
  # bridge setup
  networking.bridges.br0.interfaces = ["enp1s0" "dummy0"];

  # Prevent br0 from being stopped when the USB upstream adapter disconnects/reconnects.
  # The default scripted networking makes br0 PartOf network-setup.service, which
  # cascades from network-addresses-enp0s20f0u6.service when the USB adapter blips.
  systemd.services.br0-netdev.partOf = lib.mkForce [];
  systemd.services.network-addresses-br0.partOf = lib.mkForce [];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = ["br0" "nebula1"];
  # networking.search = [];
  networking.nat = {
    enable = true;
    # TODO: reduce duplication with trustedInterfaces
    internalInterfaces = ["br0"];
    externalInterface = "enp0s20f0u6";
  };
  networking.useDHCP = false;
  networking.networkmanager.enable = false;
  #networking.resolvconf.enable = false;
  networking.nameservers = [
    "127.0.0.1"
  ];
  networking.search = ["lan"];
  networking.dhcpcd.extraConfig = ''
    nohook resolv.conf
    nooption domain_name_servers
    nooption domain_name
    nooption domain_search
  '';
  networking.interfaces = {
    dummy0 = {
      virtual = true;
    };
    # Upstream
    enp0s20f0u6 = {
      useDHCP = true;
    };
    # Downstream
    br0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.3.1";
          prefixLength = 24;
        }
      ];
    };
  };
  networking.nftables = {
    enable = true;
    tables."router" = {
      family = "inet";
      content = ''
        # dnat example
        # chain prerouting {
        #   type nat hook prerouting priority -100; policy accept;
        #   # forward port 9735 to nodecan
        #   iifname "eth0" tcp dport 9735 dnat ip to 100.120.212.39
        # }

        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          # masquerade to public internet, private lan
          oifname "br0" masquerade
          oifname "enp0s20f0u6" masquerade
        }

        chain forward {
          type filter hook forward priority 0; policy drop;

          # allow forwarded traffic coming from lan heading to public internet
          iifname "br0" oifname "enp0s20f0u6" accept
          # allow expected replies from internet to lan traffic
          iifname "enp0s20f0u6" oifname "br0" ct state {established, related} accept

          # allow Nebula VPN to access local LAN (for Home Assistant access)
          iifname "nebula1" oifname "br0" accept
          # allow LAN to reach Nebula (bidirectional)
          iifname "br0" oifname "nebula1" accept

          # forwarding example
          # allow forwarded traffic from public net to our proxied lightning node
          # iifname "eth0" oifname "tailscale0" tcp dport 9735 counter accept comment "accept lightning"
        }
      '';
    };
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "br0";
      bind-interfaces = true;

      dhcp-range = "192.168.3.50,192.168.3.250,24h";
      dhcp-authoritative = true;
      domain = "lan";
      expand-hosts = true;

      server = [
        "1.1.1.1"
        "8.8.8.8"
      ];

      # reservations
      dhcp-host = [
        "aa:bb:cc:dd:ee:01,device1,192.168.3.2"
        "aa:bb:cc:dd:ee:02,homeassistant,192.168.3.230"
      ];

      # dhcp options
      dhcp-option = [
      ];
    };
  };

  services.avahi = {
    enable = true;
    reflector = false; # Reflect mDNS across interfaces (if using VLANS say)
    allowInterfaces = ["br0"];
    nssmdns4 = true; # Enable mDNS NSS module for .local resolution
    #publish = {
    #  enable = true;
    #  addresses = true;
    #  workstation = true;
    #  domain = true;
    #  hinfo = true;
    #  userServices = true;
    #};
    openFirewall = false; # Open mDNS ports in firewall if enabled
  };
}
