{ config, pkgs, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "us";

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.sessionPackages = [ pkgs.gnome.gnome-session.sessions ];

  services.gnome.tracker-miners.enable = false;
  services.gnome.tracker.enable = false;

  programs.gnome-terminal.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-text-editor
    gnome.nautilus
  ];
}
