{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware/intel.nix
    ./components/workstation.nix

    ./misc/additional-users.nix
  ];
  networking.hostName = "xps";
}
