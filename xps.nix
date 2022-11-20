{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware/intel.nix
    ./components/workstation.nix
  ];
  networking.hostName = "xps";
}
