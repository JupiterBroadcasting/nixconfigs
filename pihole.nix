{
  virtualisation = {
    containers.enable = true;

    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    # Run pihole as a podman container, but we can manage it with systemd.
    oci-containers = {
      backend = "podman";
      containers.pihole = {
        image = "pihole/pihole:latest";
        environment = {
          TZ = "America/New_York";
          WEBPASSWORD = "CHANGEME";
          FTLCONF_LOCAL_IPV4 = "192.168.1.2";
          INTERFACE = "eno1";
        };
        autoStart = true;
        ports = [
          "53:53/udp"
          "53:53/tcp"
          "80:80/tcp"
        ];
        volumes = [
          "/opt/pihole/etc:/etc/pihole"
          "/opt/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
        ];
        extraOptions = [ "--network=host" ];
      };
    };
  };

  # Open up the host's firewall for access to pihole.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 53 80 ];
    allowedUDPPorts = [ 53 ];
  };
}
