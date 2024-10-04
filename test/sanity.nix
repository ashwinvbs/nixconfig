# If building in isolation, build with the following command
# nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-24.05 -I nixos-config=./sanity.nix
# Ref: https://nix.dev/tutorials/nixos/nixos-configuration-on-vm

{ ... }:

{
  imports = [ ../components ];
  networking.hostName = "testing";

  installconfig = {
    auto_timezone = true;
    enable_impermanence = true;
    hardware = {
      intel = true;
      amdgpu = true;
    };
    users.allow_rad = true;
    workstation_components = true;
  };

  programs.chromium.enable = true;
  services.fprintd.enable = true;
  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
  };
}