# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    ./components/base.nix
    ./components/dev-software.nix
    ./components/gnome.nix
    ./components/keychron-fix.nix
    ./components/misc.nix
    ./components/nuc.nix
    ./components/users.nix
  ];
}

