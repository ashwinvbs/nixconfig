{ config, lib, pkgs, ... }:

let
  impermanence = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  };
in
{
  virtualisation.docker.enable = true;
  users.users.ashwin.extraGroups = [ "docker" ];

  imports = [ "${impermanence}/nixos.nix" ];
  environment.persistence."/state" = {
    directories = [
      "/var/lib/docker"
    ];
  };
}
