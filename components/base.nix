{ config, lib, pkgs, ... }:

{
  config = {
    #################################################################################################
    # Boot and timezone configuration
    #################################################################################################

    boot.loader.grub.enable = false;
    time.timeZone = lib.mkDefault "America/New_York";

    #################################################################################################
    # Network configuration
    #################################################################################################

    # Default nameservers
    networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

    #################################################################################################
    # Default programs and services
    #################################################################################################

    system.autoUpgrade.enable = true;

    services = {
      # Networking/remote access services
      openssh.enable = true;
      tailscale.enable = true;
    };

    # Disable offline documentation. their value is limited
    documentation = {
      doc.enable = false;
      info.enable = false;
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

    environment.systemPackages = with pkgs; [
      # Packages for dotfile management
      pinentry-all
      yadm
    ];

    users.mutableUsers = false;
  };
}
