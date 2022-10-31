{ config, pkgs, ... }:

{
  imports = [
    ./hardware/amdgpu.nix
    ./hardware/intel.nix
    ./components/remote.nix
  ];
  networking.hostName = "rig2";
}
