{
  config,
  lib,
  pkgs,
  ...
}:

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
    services.resolved = {
      enable = true;
      settings.Resolve = {
        Domains = [ "~." ];
        FallbackDNS = [
          "[IP_ADDRESS]#one.one.one.one"
          "[IP_ADDRESS]#one.one.one.one"
        ];
        DNSOverTLS = "true";
      };
    };

    networking.nameservers = [
      "1.1.1.1#one.one.one.one"
      "1.0.0.1#one.one.one.one"
    ];

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
    documentation.enable = false;

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

      ssh = {
        startAgent = true;
        enableAskPassword = true;
      };
    };

    environment.systemPackages = with pkgs; [
      # Packages for dotfile management
      pinentry-all
      yadm
    ];

    users.mutableUsers = false;
  };
}
