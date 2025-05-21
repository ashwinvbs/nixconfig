# If building in isolation, build with the following command
# nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-24.11 -I nixos-config=./sanity.nix
# Ref: https://nix.dev/tutorials/nixos/nixos-configuration-on-vm

{ ... }:

{
  imports = [ ../components ];
  networking.hostName = "testing";

  installconfig = {
    hardware = {
      intelgpu = true;
      amdgpu = true;
    };
    workstation_components = true;
  };

  programs.firefox.enable = true;
  services.fprintd.enable = true;
  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };
}
