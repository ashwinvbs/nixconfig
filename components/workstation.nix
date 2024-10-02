{ config, lib, pkgs, ... }:

{
  imports = [ ./installconfig.nix ];

  config = lib.mkIf config.installconfig.workstation_components {
    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.excludePackages = [ pkgs.xterm ];

    # Configure keymap in X11
    services.xserver.xkb.layout = "us";

    # Enable the GNOME Desktop Environment.
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    # Enable flatpak on workstation machines.
    services.flatpak.enable = true;

    # Enable firefox
    programs.firefox.enable = true;

    #################################################################################################
    # Autotimezone configuration
    #################################################################################################
    systemd.services.tzupdate = {
      description = "attempts updating timezone, fails if network is unavailable";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.tzupdate}/bin/tzupdate -z /etc/zoneinfo -d /dev/null";
      };
    };
    systemd.timers.tzupdate = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "10m";
        Unit = "tzupdate.service";
      };
    };


    #################################################################################################
    # Misc peripheral configuration
    #################################################################################################
    hardware.steam-hardware.enable = true;
    services.udev.packages = [
      pkgs.android-udev-rules
    ];
    # Above rule spams journal if adbusers group does not exist
    users.groups.adbusers = {};
    # Allow workstations to pass usb devices to virtual machines
    virtualisation.spiceUSBRedirection.enable = true;

    # This config is required to enable function keys in Keychron K1 keyboard
    environment.etc."modprobe.d/keychron.conf".text = "options hid_apple fnmode=0";

    # Add keyd for misc keyboard configuration
    services.keyd.enable = true;
  };
}
