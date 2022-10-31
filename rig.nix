{ config, pkgs, ... }:

{
  imports = [
    ./components/remote.nix
    ./hardware/amdgpu.nix
  ];
  networking.hostName = "rig2";
}
