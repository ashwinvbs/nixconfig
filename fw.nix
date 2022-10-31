{ config, lib, pkgs, ... }:

{
  imports = [ ./components/workstation.nix ];
  networking.hostName = "fw";

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
