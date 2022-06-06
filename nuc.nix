# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports = [
    # Common configuration
    ./components/base.nix
    ./components/users.nix

    # Machine specific configuration
    ./components/bluetooth.nix
    ./components/gnome.nix
    ./components/keychron-fix.nix
    ./components/vm.nix
  ];

  networking.hostName = "nuc";

  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  users.users.ashwin.hashedPassword = lib.strings.fileContents secrets/ashpass.txt;
}
