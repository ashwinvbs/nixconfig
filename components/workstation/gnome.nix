{ config, pkgs, ... }:

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
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "us";

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.sessionPackages = [ pkgs.gnome.gnome-session.sessions ];

  networking.networkmanager.enable = mkDefault true;

  services.gnome.tracker-miners.enable = false;
  services.gnome.tracker.enable = false;

  programs.gnome-terminal.enable = true;

  environment.systemPackages = with pkgs.gnome; [
    adwaita-icon-theme
    gnome-backgrounds
    gnome-bluetooth
    gnome-themes-extra
    nautilus
    nixos-background-info
    pkgs.glib # for gsettings program
    pkgs.gnome-console
    pkgs.gnome-menus
    pkgs.gnome-text-editor
    pkgs.gtk3.out # for gtk-launch program
    pkgs.xdg-user-dirs # Update user dirs as described in http://freedesktop.org/wiki/Software/xdg-user-dirs/
  ];

      # VTE shell integration for gnome-console
      programs.bash.vteIntegration = true;
      # Override default mimeapps for nautilus
      environment.sessionVariables.XDG_DATA_DIRS = [ "${mimeAppsList}/share" ];
}
