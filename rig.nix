{ config, pkgs, ... }:

{
  imports = [
    ./components/remote.nix
    ./hardware/gpu/amd.nix
  ];
  networking.hostName = "rig2";
}
