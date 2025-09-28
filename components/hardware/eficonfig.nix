{ config, lib, pkgs, ... }:

{
  config = lib.mkIf pkgs.stdenv.hostPlatform.isEfi {
    # Default boot configuration for UEFI systems
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
