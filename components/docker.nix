{ config, lib, pkgs, ... }:

{
  virtualisation.docker.enable = true;
  users.users.ashwin.extraGroups = [ "docker" ];

  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];
  environment.persistence."/state" = {
    directories = [
      "/var/lib/docker"
    ];
  };
}
