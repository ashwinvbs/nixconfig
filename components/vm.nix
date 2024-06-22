# To enable docker, set virtualisation.libvirtd.enable = true;

{ config, lib, ... }:

{
  config = lib.mkIf config.virtualisation.libvirtd.enable {
    programs.dconf.enable = true;
    users.users.ashwin.extraGroups = [ "libvirtd" ];
  };
}
