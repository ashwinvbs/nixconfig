{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.installconfig.enable_virtual_camera = lib.mkEnableOption "Enable v4l2loopback virtual camera";

  config = lib.mkIf config.installconfig.enable_virtual_camera {
    # Kernel module setup
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];

    # Set initial kernel module settings
    boot.extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 card_label="Virtual Camera" video_nr=10
    '';
  };
}
