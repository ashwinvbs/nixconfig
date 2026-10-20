{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.hostPlatform.isEfi {
      # Default boot configuration for UEFI systems
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    })

    (lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 {
      # Cross-emulate aarch64-linux through binfmt/qemu-user
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    })
  ];
}
