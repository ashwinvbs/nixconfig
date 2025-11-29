{ config, lib, pkgs, ... }:

{
  options.installconfig.workstation_components =
    lib.mkEnableOption "Configure the machine to be a workstation";

  config = lib.mkIf config.installconfig.workstation_components {
    # Disable speech services. Include this config here as its installed for all graphics-desktops.
    services.speechd.enable = false;

    # Enable auto updating timezone information
    services.tzupdate.enable = true;

    services = {
      # Enable the GNOME Desktop Environment.
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    # Enable flatpak on workstation machines.
    services.flatpak.enable = true;

    # Enable chromium
    programs.chromium.enable = true;

    #################################################################################################
    # Misc peripheral configuration
    #################################################################################################
    hardware = {
      keyboard.qmk.enable = true;
      steam-hardware.enable = true;
    };

    # Allow workstations to pass usb devices to virtual machines
    virtualisation.spiceUSBRedirection.enable = true;

    # This config is required to enable function keys in Keychron K1 keyboard
    environment.etc."modprobe.d/keychron.conf".text =
      "options hid_apple fnmode=0";
  };
}
