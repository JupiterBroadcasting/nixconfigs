{
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "your@email.com";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      dnsPropagationCheck = true;
      credentialsFile = "/etc/nixos/cloudflare.env";
      # Use staging server.
      # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    };
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts = {
      # Hosted on domain.io
      "nextcloud" = {
        serverName = "domain.io";
        enableACME = true;
        acmeRoot = null; # Use DNS-01 Challenge.
        forceSSL = true;
        # listen = [{port = 443; addr="0.0.0.0"; ssl=true;}];
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
        };
        extraConfig = "client_max_body_size 1000M;";
      };

      # Hosted on subdomains of domain.io
      "books.domain.io" = {
        enableACME = true;
        acmeRoot = null; # Use DNS-01 Challenge.
        forceSSL = true;
        # listen = [{port = 443; addr="0.0.0.0"; ssl=true;}];
        locations."/" = {
          proxyPass = "http://127.0.0.1:13378";
          proxyWebsockets = true;
        };
      };
      "jellyfin.domain.io" = {
        enableACME = true;
        acmeRoot = null; # Use DNS-01 Challenge.
        forceSSL = true;
        # listen = [{port = 443; addr="0.0.0.0"; ssl=true;}];
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
          proxyWebsockets = true;
        };
      };
      "plex.domain.io" = {
        enableACME = true;
        acmeRoot = null; # Use DNS-01 Challenge.
        forceSSL = true;
        # listen = [{port = 443; addr="0.0.0.0"; ssl=true;}];
        locations."/" = {
          proxyPass = "http://127.0.0.1:32400";
          proxyWebsockets = true;
        };
      };
      "code.domain.io" = {
        enableACME = true;
        acmeRoot = null; # Use DNS-01 Challenge.
        forceSSL = true;
        # listen = [{port = 443; addr="0.0.0.0"; ssl=true;}];
        locations."/" = {
          proxyPass = "http://127.0.0.1:8444";
          proxyWebsockets = true;
        };
      };
      #        locations."/" = {proxyPass = "http://127.0.0.1:81"; proxyWebsockets = true;};
      #      };
    };
  };
}
