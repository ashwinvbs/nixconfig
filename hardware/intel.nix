{ config, lib, pkgs, ... }:

{
  options.installconfig.hardware.intel = lib.mkEnableOption "Enable driver support for intel cpu/gpu";

  config = lib.mkIf config.installconfig.hardware.intel {
    # CPU configuration
    hardware.cpu.intel.updateMicrocode =
      config.hardware.enableRedistributableFirmware;

    # GPU configuration
    boot.initrd.kernelModules = [ "i915" ];

    environment.variables = {
      VDPAU_DRIVER = lib.mkIf config.hardware.opengl.enable (lib.mkDefault "va_gl");
    };

    hardware.opengl.extraPackages = with pkgs; [
      vaapiIntel
      libvdpau-va-gl
      intel-media-driver
    ];
  };
}
