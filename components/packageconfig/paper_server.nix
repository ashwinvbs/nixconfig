{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.installconfig.enable_paper_server = lib.mkEnableOption "Enables printer and scanner services over LAN";

  config = lib.mkIf config.installconfig.enable_paper_server {
    # PRINTER CONFIGURATION (CUPS)
    services.printing = {
      enable = true;
      drivers = [ pkgs.hplipWithPlugin ];

      # Network Sharing Settings
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
      browsing = true;
      defaultShared = true;
    };

    # SCANNER CONFIGURATION (SANE + Brother Drivers)
    hardware.sane = {
      enable = true;
      brscan5.enable = true;
      extraBackends = [ pkgs.sane-airscan ];
      disabledDefaultBackends = [ "escl" ];
    };
    services.udev.packages = [ pkgs.sane-airscan ];

    # AIRSANE BRIDGE (For Android/eSCL support)
    # This makes your USB scanner look like a Network AirScan device
    # systemd.services.airsane = {
    #   description = "SANE to eSCL (AirScan) Bridge";
    #   after = [
    #     "network.target"
    #     "sane-backends.service"
    #   ];
    #   wantedBy = [ "multi-user.target" ];

    #   serviceConfig = {
    #     # 1. Use a transient, unprivileged user
    #     DynamicUser = true;

    #     # 2. Grant access to hardware groups
    #     SupplementaryGroups = [
    #       "scanner"
    #       "lp"
    #     ];

    #     # 3. Execution
    #     ExecStart = "${pkgs.sane-airscan}/bin/airsane -p 8090";
    #     Restart = "always";
    #   };
    # };

    # NETWORK DISCOVERY (AVAHI)
    # Allows your phone and laptops to "see" the devices without an IP
    services.avahi = {
      enable = lib.mkForce true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
        addresses = true;
      };
    };

    # FIREWALL
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        631 # CUPS
        8090 # AirSane
      ];
      allowedUDPPorts = [
        631 # CUPS/IPP
        5353 # mDNS (Discovery)
      ];
    };
  };
}
