{ config, pkgs, ... }:

{
  imports = [
    ./hardware/amdgpu.nix
    ./hardware/intel.nix
    ./components/common.nix
  ];
  networking.hostName = "rig2";
}
