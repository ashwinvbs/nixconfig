{ config, lib, pkgs, ... }:

{
  config.security.sudo.extraConfig = lib.mkIf config.security.sudo.enable ''
    Defaults        env_keep+=SSH_AUTH_SOCK
    Defaults        lecture=never
  '';
}
