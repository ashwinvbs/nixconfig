{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware/amdgpu.nix
    ./components/workstation.nix
  ];
  networking.hostName = "xps";
}
