# To enable flatpak, set services.flatpak.enable = true;

{ config, lib, ... }:

{
  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];

  config = lib.mkIf config.services.flatpak.enable {
    environment.persistence."/nix/state" = {
      users.ashwin.directories = [ ".var/app" ];
    };
  };
}
