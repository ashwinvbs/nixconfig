{ config, pkgs, ... }:

{
  # Allow kernel to read and execute aarch64 binaries
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
 
  environment.systemPackages = with pkgs; [
    nixos-generators
  ];
}
