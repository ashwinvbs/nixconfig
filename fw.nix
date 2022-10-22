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
    ./components/chromium.nix
    ./components/gnome.nix
    ./components/keychron-fix.nix
    ./components/radio.nix
    ./components/raspi-host.nix
  ];

  networking.hostName = "fw";

  networking.useDHCP = false;
  networking.interfaces.wlp166s0.useDHCP = true;

  users.users.ashwin.hashedPassword = lib.strings.fileContents secrets/ashpass.txt;

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
