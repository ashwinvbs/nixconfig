{ config, lib, pkgs, ... }:

let
  # Prioritize nautilus by default when opening directories
  mimeAppsList = pkgs.writeTextFile {
    name = "gnome-mimeapps";
    destination = "/share/applications/mimeapps.list";
    text = ''
      [Default Applications]
      inode/directory=nautilus.desktop;org.gnome.Nautilus.desktop
    '';
  };
in
{
  config = lib.mkIf config.installconfig.workstation-components.enable {
    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.excludePackages = [ pkgs.xterm ];

    # Configure keymap in X11
    services.xserver.layout = "us";

    # Enable the GNOME Desktop Environment.
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    # gnome.core-os-services overrides
    services.gnome.gnome-online-accounts.enable = false;
    # Would like to disable but cannot
    # services.gnome.at-spi2-core.enable = true;
    # services.gnome.evolution-data-server.enable = true;
    # services.gnome.gnome-online-miners.enable = true;

    # gnome.core-shell overrides
    services.gnome.gnome-initial-setup.enable = false;
    services.gnome.gnome-remote-desktop.enable = false;
    services.gnome.gnome-user-share.enable = false;
    services.gnome.rygel.enable = false;
    services.system-config-printer.enable = false;
    services.avahi.enable = false;

    environment.gnome.excludePackages = [
      pkgs.gnome-tour
      pkgs.gnome-user-docs
      pkgs.orca
    ];

    # disable gnome.core-utilities and include minimal replacements
    services.gnome.core-utilities.enable = false;
    environment.systemPackages = with pkgs.gnome; [
      gnome-music
      nautilus
      pkgs.freetube
      pkgs.gnome-console
      pkgs.gnome-text-editor
    ];

    programs.file-roller.enable = true;

    # VTE shell integration for gnome-console
    programs.bash.vteIntegration = true;

    # Override default mimeapps for nautilus
    environment.sessionVariables.XDG_DATA_DIRS = [ "${mimeAppsList}/share" ];
  };
}
