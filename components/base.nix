{ config, pkgs, ... }:

let
  impermanence = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  };
in {
  fileSystems."/".options = [ "defaults" "size=2G" "mode=755" ];
  fileSystems."/state".neededForBoot = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  # Disable sleep suspend and hibernate.
  # Power management is wonky at times and broken at worst
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  nix.gc = {
    automatic = true;
    dates = "hourly";
    options = "--delete-older-than 1d";
  };

  # https://github.com/NixOS/nixpkgs/issues/87802
  boot.kernelParams = [ "ipv6.disable=1" ];
  networking.enableIPv6 = false;

  # Git is required for pulling nix configuration
  environment.systemPackages = with pkgs; [
    git
    pciutils
    usbutils

    # move to users on merge from statless branch
    gnupg
    pinentry
    yadm
  ];

  programs.gnupg.agent.enable = true;

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

  imports = [ "${impermanence}/nixos.nix" ];
  environment.persistence."/state" = {
    directories = [
      "/var/log"
    ];
  };
  environment.etc."machine-id".source = "/state/machine-id";
}
