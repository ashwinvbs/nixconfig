# If building in isolation, build with the following command
# nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-24.05 -I nixos-config=./sanity.nix
# Ref: https://nix.dev/tutorials/nixos/nixos-configuration-on-vm

{ ... }:

{
  imports = [ ../components ];
  networking.hostName = "testing";
  installconfig.enable_full_codecoverage_for_test = true;
}