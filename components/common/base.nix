{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # enable automatic timemzone setting
  services.geoclue2.enableDemoAgent = true;
  services.localtime.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  # https://github.com/NixOS/nixpkgs/issues/87802
  boot.kernelParams = [ "ipv6.disable=1" ];
  networking.enableIPv6 = false;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  services.fstrim.enable = true;
}
