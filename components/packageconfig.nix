# Package-wise configuration applied with they are enabled.

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
  config = lib.mkMerge[
    ( lib.mkIf config.services.openssh.enable {
      services.openssh.settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    } )

    ( lib.mkIf config.programs.tmux.enable {
      programs.tmux = {
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
    } )

    ( lib.mkIf config.programs.chromium.enable {
      environment.systemPackages = with pkgs; [
        # programs.chromium.enable = true only enables policy o.0 :| ???
        chromium
      ];
      nixpkgs.config = lib.mkDefault {
        allowUnfree = true;
        chromium.enableWideVine = true;
      };

      programs.chromium.extraOpts = {
        "AdvancedProtectionAllowed" = false;
        "AutofillAddressEnabled" = false;
        "AutofillCreditCardEnabled" = false;
        "BrowserSignin" = 0;
        "CloudPrintProxyEnabled" = false;
        "HideWebStoreIcon" = true;
        "MetricsReportingEnabled" = false;
        "PasswordManagerEnabled" = false;
        "PaymentMethodQueryEnabled" = false;
        "ProfilePickerOnStartupAvailability" = 1;
        "RemoteAccessHostAllowRemoteAccessConnections" = false;
        "RemoteAccessHostAllowRemoteSupportConnections" = false;
        "RemoteDebuggingAllowed" = false;
        "SharedClipboardEnabled" = false;
        "ShowAppsShortcutInBookmarkBar" = false;
        "ShowHomeButton" = false;
        "SpellCheckServiceEnabled" = false;
        "SyncDisabled" = true;

        "ExtensionInstallForcelist" = [
          "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
          "apjcbfpjihpedihablmalmbbhjpklbdf" # AdGuard AdBlocker
        ];
      };
    } )

    ( lib.mkIf config.services.xserver.desktopManager.gnome.enable {
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

      environment.gnome.excludePackages = with pkgs; [
        gnome-tour
        gnome-user-docs
        orca
      ];

      # disable gnome.core-utilities and include minimal replacements
      services.gnome.core-utilities.enable = false;
      environment.systemPackages = with pkgs; [
        gnome-console
        gnome-text-editor
        gnome.nautilus
      ];

      programs.file-roller.enable = true;

      # VTE shell integration for gnome-console
      programs.bash.vteIntegration = true;

      # Override default mimeapps for nautilus
      environment.sessionVariables.XDG_DATA_DIRS = [ "${mimeAppsList}/share" ];
    } )

    ( lib.mkIf config.programs.firefox.enable {} )
  ];
}