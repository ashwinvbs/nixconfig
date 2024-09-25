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

  ## Cleanup operations
  # Specify size constraints for nix store
  # Free upto 1G when free space falls below 100M
  nix.extraOptions = ''
    min-free = ${toString (100 * 1024 * 1024)}
    max-free = ${toString (1024 * 1024 * 1024)}
  '';

  # Clean up week old packages
  # NOTE: It is possible that too many initrd disks are created and /boot runs out of space.
  # I suspect the logs wont have any indication of the error. Newer generations would just stop appearing.
  # If this happens, start manually deleting generations.
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

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

  security.sudo.extraConfig = ''
    Defaults        lecture=never
  '';

  services.fwupd.enable = true;

  environment.shellAliases = {
    reboot_to_firmware = "systemctl reboot --firmware-setup";
    debug_kernel_interrupts = "watch -n0.1 -d --no-title cat /proc/interrupts";
  };
}
