{
  # Paperless
  services.paperless.enable = true;
  services.paperless.address = "0.0.0.0";
  # Paperless AI
  systemd.tmpfiles.rules = [
    "d '/var/lib/paperless-ai' 0770 paperless paperless - -"
  ];
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
    oci-containers = {
      backend = "podman";
      containers.paperlessngxai = {
        image = "docker.io/clusterzx/paperless-ai:nightly";
        autoStart = true;

        environment = {
          # TODO: refer paperless user
          PUID = "315";
          PGID = "315";
          PAPERLESS_AI_PORT = "3300";
          RAG_SERVICE_URL = "http://localhost:8000";
          RAG_SERVICE_ENABLED = "true";
        };

        ports = [
          "3300:3300"
        ];

        volumes = [
          "/var/lib/paperless-ai:/app/data"
        ];

        extraOptions = [
          #"--cap-drop=ALL"  TODO: included in upstream docker-compose, seems to break app
          "--security-opt=no-new-privileges:true"
        ];
      };
    };
  };
  systemd.services.podman-paperlessngxai = {
    after = ["systemd-tmpfiles-setup.service"];
    requires = ["systemd-tmpfiles-setup.service"];
  };

  # Karakeep
  services.karakeep.enable = true;
  services.karakeep.extraEnvironment = {
    PORT = "3003";
    CRAWLER_FULL_PAGE_SCREENSHOT = "true";
    CRAWLER_FULL_PAGE_ARCHIVE = "true";
    # TODO: systemd credential or similar
    OPENAI_API_KEY = "...";
    OPENAI_BASE_URL = "https://openrouter.ai/api/v1";
    INFERENCE_ENABLE_AUTO_SUMMARIZATION = "true";
  };

  # Pinchflat
  services.pinchflat.enable = true;
  services.pinchflat.selfhosted = true;

  services.ersatztv.enable = true;
  services.ersatztv.bindReadOnlyPaths = [
    "/var/lib/pinchflat/media:/media/pinchflat"
  ];
}
