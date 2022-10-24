{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  # Disable sleep suspend and hibernate.
  # Power management is wonky at times and broken at worst
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # https://github.com/NixOS/nixpkgs/issues/87802
  boot.kernelParams = [ "ipv6.disable=1" ];
  networking.enableIPv6 = false;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
}
