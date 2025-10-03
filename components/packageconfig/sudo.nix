{ config, lib, pkgs, ... }:

{
  config.security.sudo.extraConfig = ''
    Defaults        env_keep+=SSH_AUTH_SOCK
    Defaults        lecture=never
  '';
}
