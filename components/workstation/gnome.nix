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

  hardware.bluetooth.enable = true;
  hardware.pulseaudio.enable = true;
  networking.networkmanager.enable = true;
  programs.dconf.enable = true;
  security.polkit.enable = true;
  services.accounts-daemon.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.hardware.bolt.enable = mkDefault true;
  services.power-profiles-daemon.enable = mkDefault true;
  services.udisks2.enable = true;
  services.upower.enable = config.powerManagement.enable;
  services.xserver.libinput.enable = mkDefault true; # for controlling touchpad settings via gnome control center
  services.xserver.updateDbusEnvironment = true;
  nixpkgs.config.vim.gui = "gtk3";
  services.gnome.glib-networking.enable = true;
  services.gnome.gnome-browser-connector.enable = mkDefault true;
  services.gnome.gnome-settings-daemon.enable = true;
  services.gvfs.enable = true;

  services.udev.packages = with pkgs.gnome; [
    # Force enable KMS modifiers for devices that require them.
    # https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1443
    mutter
  ];

  # Explicitly enabled since GNOME will be severely broken without these.
  xdg.mime.enable = true;
  xdg.icons.enable = true;

  # Harmonize Qt5 application style and also make them use the portal for file chooser dialog.
  qt5 = {
    enable = mkDefault true;
    platformTheme = mkDefault "gnome";
    style = mkDefault "adwaita";
  };
  fonts.fonts = with pkgs; [
    cantarell-fonts
    dejavu_fonts
    source-code-pro # Default monospace font in 3.32
    source-sans
  ];

  services.geoclue2.enable = mkDefault true;
  services.geoclue2.enableDemoAgent = false; # GNOME has its own geoclue agent

  services.geoclue2.appConfig.gnome-datetime-panel = {
    isAllowed = true;
    isSystem = true;
  };
  services.geoclue2.appConfig.gnome-color-panel = {
    isAllowed = true;
    isSystem = true;
  };
  services.geoclue2.appConfig."org.gnome.Shell" = {
    isAllowed = true;
    isSystem = true;
  };

  # Needed for themes and backgrounds
  environment.pathsToLink = [
    "/share" # TODO: https://github.com/NixOS/nixpkgs/issues/47173
  ];

  environment.systemPackages = with pkgs.gnome; [
    adwaita-icon-theme
    gnome-backgrounds
    gnome-bluetooth
    gnome-themes-extra
    nautilus
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
