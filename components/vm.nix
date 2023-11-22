# To enable docker, set virtualisation.libvirtd.enable = true;

{ config, lib, ... }:

{
  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];

  config = lib.mkIf config.virtualisation.libvirtd.enable {
    programs.dconf.enable = true;
    users.users.ashwin.extraGroups = [ "libvirtd" ];
    environment.persistence."/nix/state" = {
      directories = [ "/var/lib/libvirt" ];
    };
  };
}
