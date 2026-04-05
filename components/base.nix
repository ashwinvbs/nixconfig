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

    # Force the Global config to have the highest priority
    services.resolved = {
      enable = true;
      # 'nameservers' sets the Global DNS
      # 'domains' with '~.' makes this the "default route" for all DNS
      domains = [ "~." ];
      fallbackDns = [ ]; # Disable fallbacks to ensure it only hits Blocky
      extraConfig = ''
        DNSStubListener=no
      '';
    };
    # Force the system to look at Blocky first
    networking.nameservers = [ "127.0.0.1" ];
    services.blocky.enable = true;

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
