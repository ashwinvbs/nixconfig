{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware/intel.nix
    ./components/common.nix
  ];
  networking.hostName = "nuc";
}
