{ config, lib, pkgs, ... }:

{
  imports = [ ./components/workstation.nix ];
  networking.hostName = "nuc";
}
