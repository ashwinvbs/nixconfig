{ config, pkgs, lib, ... }:

{
  options.installconfig.components.gaming = lib.mkEnableOption "Enables software for gaming";

  config = lib.mkIf config.installconfig.components.gaming {
    environment.systemPackages = with pkgs; [
      heroic
      scanmem
    ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
    };
  };
}