{ config, lib, pkgs, ... }:

{
  options.installconfig.impermanence = lib.mkEnableOption "Enable impermanence";

  imports = [
    ./autoupgrade.nix
    ./chromium.nix
    ./firefox.nix
    ./gnome.nix
    ./misc_impermanence.nix
    ./nix.nix
    ./ollama.nix
    ./openssh.nix
    ./sudo.nix
    ./tailscale.nix
    ./tmux.nix
    ./tzupdate.nix
  ];
}
