{ config, pkgs, ... }:

{
  # Git is required for pulling nix configuration
  environment.systemPackages = with pkgs; [
    git
    htop
    nixos-option
  ];

  programs.tmux = {
    enable = true;
    shortcut = "k";
    aggressiveResize = true;
    baseIndex = 1;

    extraConfig = ''
      # Split panes using | and -
      bind | split-window -h
      bind - split-window -v
      unbind '"'
      unbind %

      # Enable mouse control (clickable windows, panes, resizable panes)
      set -g mouse on

      # Don't rename windows automatically
      set-option -g allow-rename off
    '';
  };

  security.sudo.extraConfig = ''
    Defaults        lecture=never
  '';

  services.udev.packages = [
    pkgs.android-udev-rules
  ];

  environment.shellAliases.reboot_to_firmware = "systemctl reboot --firmware-setup";
}
