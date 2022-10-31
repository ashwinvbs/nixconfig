{ config, pkgs, ... }:

{
  imports = [
    ./components/remote.nix

    ./components/misc/amd-gpu-drivers.nix
  ];
  networking.hostName = "rig2";
}
