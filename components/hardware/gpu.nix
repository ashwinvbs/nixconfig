{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.installconfig.hardware = {
    amdgpu = lib.mkEnableOption "Enable driver support for amdgpu";
    intelgpu = lib.mkEnableOption "Enable driver support for intel gpu";
  };

  config = lib.mkMerge [
    (lib.mkIf config.installconfig.hardware.amdgpu {
      environment.systemPackages = with pkgs; [ radeontop ];

      services.xserver.videoDrivers = [ "amdgpu" ];
    })

    (lib.mkIf config.installconfig.hardware.intelgpu {
      environment.systemPackages = with pkgs; [ intel-gpu-tools ];

      boot.initrd.kernelModules = [ "i915" ];

      environment.variables = {
        VDPAU_DRIVER = "va_gl";
      };

      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
        vpl-gpu-rt
      ];
    })
  ];
}
