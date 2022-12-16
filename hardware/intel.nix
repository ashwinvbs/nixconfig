{ config, lib, pkgs, ... }:

{
  # CPU configuration
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Alder Lake CPUs benefit from kernel 5.18 for ThreadDirector
  # https://www.tomshardware.com/news/intel-thread-director-coming-to-linux-5-18
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # GPU configuration
  boot.initrd.kernelModules = [ "i915" ];

  environment.variables = {
    VDPAU_DRIVER = lib.mkIf config.hardware.opengl.enable (lib.mkDefault "va_gl");
  };

  hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    vaapiVdpau
    libvdpau-va-gl
    intel-media-driver
  ];
}
