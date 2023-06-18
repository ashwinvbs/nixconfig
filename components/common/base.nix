{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set default timezone to EST
  time.timeZone = lib.mkDefault "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  # https://github.com/NixOS/nixpkgs/issues/87802
  boot.kernelParams = [ "ipv6.disable=1" ];
  networking.enableIPv6 = false;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  services.fstrim.enable = true;

  # File system defines
  fileSystems."/".options = [ "defaults" "size=2G" "mode=755" ];

  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];
  environment.persistence."/nix/state" = {
    directories = [
      "/etc/nixos"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
