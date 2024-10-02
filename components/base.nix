{ config, lib, pkgs, ... }:

{
  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Default timezone and locale
  time.timeZone = lib.mkDefault "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  #################################################################################################
  # Network configuration
  #################################################################################################

  # Disable IPV6 https://github.com/NixOS/nixpkgs/issues/87802
  boot.kernelParams = [ "ipv6.disable=1" ];
  networking.enableIPv6 = false;

  # Default nameservers
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # install Tailscale service by default. long live tailscale!
  services.tailscale.enable = true;

  #################################################################################################
  # Disk/free space management
  #################################################################################################

  # Enable fstrim for ssd/nvme
  services.fstrim.enable = true;

  #################################################################################################
  # Programs/Packages/Command aliases
  #################################################################################################

  # Git is required for pulling nix configuration
  environment.systemPackages = with pkgs; [
    git
    htop
    nixos-option
  ];

  programs.tmux.enable = true;

  services.fwupd.enable = true;

  environment.shellAliases = {
    reboot_to_firmware = "systemctl reboot --firmware-setup";
    debug_kernel_interrupts = "watch -n0.1 -d --no-title cat /proc/interrupts";
  };
}
