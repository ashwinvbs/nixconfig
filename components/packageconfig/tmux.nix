{ config, lib, pkgs, ... }:

{
  config.programs.tmux = {
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
}
