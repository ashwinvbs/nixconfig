# To enable docker, set virtualisation.docker.enable = true;

{ config, lib, ... }:

{
  config = lib.mkIf config.virtualisation.docker.enable {
    users.users.ashwin.extraGroups = [ "docker" ];
  };
}
