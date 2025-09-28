{ config, lib, pkgs, ... }:

{
  options.installconfig.hardware.rpi4 = lib.mkEnableOption "Enable driver and boot support for Raspberry pi 4";

  config = lib.mkIf config.installconfig.hardware.rpi4 {
    boot = {
      kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
      loader.generic-extlinux-compatible.enable = true;
    };
    networking.wireless.enable = true;
  };
}
