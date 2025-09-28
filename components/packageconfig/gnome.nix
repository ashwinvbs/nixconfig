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
  config = lib.mkIf config.services.xserver.desktopManager.gnome.enable {
    # gnome.core-os-services overrides
    services.gnome.gnome-online-accounts.enable = false;
    services.gnome.evolution-data-server.enable = lib.mkForce true;

    # Would like to disable but cannot
    # services.gnome.at-spi2-core.enable = true;

    # gnome.core-shell overrides
    services.gnome.gnome-initial-setup.enable = false;
    services.gnome.gnome-remote-desktop.enable = false;
    services.gnome.gnome-user-share.enable = false;
    services.gnome.rygel.enable = false;
    services.system-config-printer.enable = false;
    services.avahi.enable = false;

    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-user-docs
      orca
    ];

    # disable gnome.core-apps and include minimal replacements
    services.gnome.core-apps.enable = false;
    environment.systemPackages = with pkgs; [
      gnome-console
      nautilus
    ];

    programs.file-roller.enable = true;

    # VTE shell integration for gnome-console
    programs.bash.vteIntegration = true;

    # Override default mimeapps for nautilus
    environment.sessionVariables.XDG_DATA_DIRS = [ "${mimeAppsList}/share" ];
  };
}
