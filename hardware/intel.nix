{ config, lib, pkgs, ... }:

{
  # CPU configuration
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

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
}
