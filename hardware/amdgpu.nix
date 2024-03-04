{ config, lib, pkgs, ... }:

{
  options.installconfig.hardware.amdgpu = lib.mkEnableOption "Enable driver support for amdgpu";

  config = lib.mkIf config.installconfig.hardware.amdgpu {
    environment.systemPackages = with pkgs; [
      radeontop
    ];

    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.opengl.driSupport = true;
    hardware.opengl.extraPackages = with pkgs; [
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
  };
}
