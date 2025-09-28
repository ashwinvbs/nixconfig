# If building in isolation, build with the following command
# nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-25.05 -I nixos-config=./sanity.nix
# Ref: https://nix.dev/tutorials/nixos/nixos-configuration-on-vm

{ ... }:

{
  imports = [ ../default.nix ];
  networking.hostName = "testing";

  installconfig = {
    devtools = true;
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

  users.users.testuser = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "testpass";
  };
}
