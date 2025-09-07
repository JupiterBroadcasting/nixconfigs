{
  # Paperless
  services.paperless.enable = true;
  services.paperless.address = "0.0.0.0";
  # TODO: paperless-ai https://github.com/clusterzx/paperless-ai

  # Karakeep
  services.karakeep.enable = true;
  services.karakeep.extraEnvironment = {
    PORT = "3003";
  };

  # Pinchflat
  services.pinchflat.enable = true;
  services.pinchflat.selfhosted = true;

  # See https://github.com/noblepayne/ersatztv-flake for how to add to your flake.
  services.ersatztv.enable = true;
  services.ersatztv.bindReadOnlyPaths = [
    "/home/wes/Downloads:/media/Downloads"
  ];
}
