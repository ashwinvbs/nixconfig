{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware/intel.nix
    ./components/workstation.nix

    ./components/misc/additional-users.nix
  ];
  networking.hostName = "xps";
}
