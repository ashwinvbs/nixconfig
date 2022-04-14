{ config, lib, pkgs, ... }:

{
  networking.hostName = "rig2";

  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp7s0.useDHCP = true;

  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.opengl.driSupport = true;
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  virtualisation.docker.enable = true;
  users.users.ashwin.extraGroups = [ "docker" ];
}
