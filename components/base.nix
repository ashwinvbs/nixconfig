{ config, lib, pkgs, ... }:

{
  #################################################################################################
  # Boot and timezone configuration
  #################################################################################################

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

  #################################################################################################
  # Default programs and services
  #################################################################################################

  services = {
    # Networking/remote access services
    openssh.enable = true;
    tailscale.enable = true;

    # Firmware management service
    fwupd.enable = true;

    # SSD management service
    fstrim.enable = true;
  };

  programs = {
    # Git is required for pulling nix configuration
    git = {
      enable = true;
      lfs.enable = true;
    };

    # Custom settings are easier to apply if package is enabled systemwide
    tmux.enable = true;

    # Enable gnupg
    gnupg.agent.enable = true;
  };

  environment = {
    sessionVariables = {
      # Make running non installed commands interactive and painless
      NIX_AUTO_RUN = 1;
      NIX_AUTO_RUN_INTERACTIVE = 1;
    };

    shellAliases = {
      reboot_to_firmware = "systemctl reboot --firmware-setup";
      debug_kernel_interrupts = "watch -n0.1 -d --no-title cat /proc/interrupts";
    };
  };
}
