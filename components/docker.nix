# To enable docker, set virtualisation.docker.enable = true;

{ config, lib, ... }:

{
  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];

  config = lib.mkIf config.virtualisation.docker.enable {
    users.users.ashwin.extraGroups = [ "docker" ];
    environment.persistence."/nix/state" = {
      directories = [ "/var/lib/docker" ];
    };
  };
}
