# /etc/nixos/nebula-doctor.nix
{
  config,
  pkgs,
  ...
}: {
  services.nebula.networks.nebula = {
    enable = true;

    ca = "/etc/nebula/ca.crt";
    cert = "/etc/nebula/doctor.crt";
    key = "/etc/nebula/doctor.key";

    staticHostMap = {
      "192.168.100.1" = ["PUBLIC_IP:4242"];
    };

    isLighthouse = false;

    lighthouses = ["192.168.100.1"];

    listen = {
      host = "::";
      port = 4242;
    };

    settings = {
      relay = {
        am_relay = false;
        use_relays = true;
        relays = ["192.168.100.1"];
      };

      lighthouse.interval = 60;

      punchy = {
        punch = true;
        respond = true;
      };

      tun = {
        dev = "nebula1";
        drop_local_broadcast = false;
        drop_multicast = false;
        # unsafe_routes not needed on gateway - clients configure routes to point here
        # Clients should add: unsafe_routes = [{route = "192.168.3.0/24"; via = "192.168.100.2";}]
      };

      logging = {
        level = "debug";
        format = "text";
      };

      firewall = {
        outbound = [
          {
            port = "any";
            proto = "any";
            host = "any";
          }
        ];

        inbound = [
          {
            port = "any";
            proto = "any";
            host = "any";
          }
        ];
      };
    };
  };

  networking.firewall.allowedUDPPorts = [4242];

  # Disable reverse path filtering for Nebula interface
  # Nebula overlay networking doesn't match routing table expectations
  boot.kernel.sysctl = {
    "net.ipv4.conf.nebula1.rp_filter" = 0;
  };
}
