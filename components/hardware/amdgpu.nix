{ config, lib, pkgs, ... }:

{
  options.installconfig.hardware.amdgpu = lib.mkEnableOption "Enable driver support for amdgpu";

  config = lib.mkIf config.installconfig.hardware.amdgpu {
    environment.systemPackages = with pkgs; [ radeontop ];

    services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
