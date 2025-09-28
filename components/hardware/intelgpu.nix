{ config, lib, pkgs, ... }:

{
  options.installconfig.hardware.intelgpu = lib.mkEnableOption "Enable driver support for intel gpu";

  config = lib.mkIf config.installconfig.hardware.intelgpu {
    environment.systemPackages = with pkgs; [ intel-gpu-tools ];

    boot.initrd.kernelModules = [ "i915" ];

    environment.variables = { VDPAU_DRIVER = "va_gl"; };

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vaapiIntel
        libvdpau-va-gl
        intel-media-driver
      ];
    };
  };
}
