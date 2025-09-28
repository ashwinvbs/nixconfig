{ config, lib, pkgs, ... }:

{
  imports = [
    ./amdgpu.nix
    ./eficonfig.nix
    ./intelgpu.nix
    ./rpi4.nix
  ];

  config = {
    services = {
      # Firmware management service
      fwupd.enable = true;

      # SSD management service
      fstrim.enable = true;
    };
  };
}
