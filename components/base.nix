{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  # Git is required for pulling nix configuration
  environment.systemPackages = with pkgs; [
    git
  ];

  users.users.ashwin = {
    isNormalUser = true;
    description = "Ashwin Balasubramaniyan";
    password = "password"; # Change this ASAP!
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };
}
