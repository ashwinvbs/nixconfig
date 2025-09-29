{ config, lib, pkgs, ... }:

{
  options.installconfig.impermanence = lib.mkEnableOption "Enable impermanence";

  imports = [
    "${
      builtins.fetchTarball {
        url =
          "https://github.com/nix-community/impermanence/archive/master.tar.gz";
      }
    }/nixos.nix"

    ./autoupgrade.nix
    ./chromium.nix
    ./devtools.nix
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
