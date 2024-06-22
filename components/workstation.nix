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
  options.installconfig.components.workstation = lib.mkEnableOption "Configure the machine to be a workstation";

  config = lib.mkIf config.installconfig.components.workstation {
    #################################################################################################
    # Gnome configuration
    #################################################################################################

    # Enable the X11 windowing system.
    services.xserver.enable = true;
    services.xserver.excludePackages = [ pkgs.xterm ];

    # Configure keymap in X11
    services.xserver.xkb.layout = "us";

    # Enable the GNOME Desktop Environment.
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

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

    # disable pulseaudio and enable pipewire
    hardware.pulseaudio.enable = lib.mkForce false;
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
    };

    environment.gnome.excludePackages = with pkgs [
      gnome-tour
      gnome-user-docs
      orca
    ];

    # disable gnome.core-utilities and include minimal replacements
    services.gnome.core-utilities.enable = false;
    environment.systemPackages = with pkgs; [
      freetube
      gnome-console
      gnome-text-editor
      gnome.gnome-music
      gnome.nautilus

      # programs.chromium.enable = true only enables policy o.0 :| ???
      chromium
    ];

    programs.file-roller.enable = true;

    # VTE shell integration for gnome-console
    programs.bash.vteIntegration = true;

    # Override default mimeapps for nautilus
    environment.sessionVariables.XDG_DATA_DIRS = [ "${mimeAppsList}/share" ];

    #################################################################################################
    # Chromium configuration
    #################################################################################################
    nixpkgs.config = {
      allowUnfree = true;
      chromium = {
        enableWideVine = true;
        # From https://chromium.googlesource.com/chromium/src/+/master/docs/gpu/vaapi.md
        commandLineArgs = "--use-gl=angle --use-angle=gl --enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiOnNvidiaGPUs --ignore-gpu-blocklist --disable-gpu-driver-bug-workaround";
      };
    };
    programs.chromium = {
      enable = true;
      extraOpts = {
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
    };

    #################################################################################################
    # Autotimezone configuration
    #################################################################################################
    systemd.services.tzupdate = {
      description = "attempts updating timezone, fails if network is unavailable";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.tzupdate}/bin/tzupdate -z /etc/zoneinfo -d /dev/null";
      };
    };
    systemd.timers.tzupdate = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "10m";
        Unit = "tzupdate.service";
      };
    };


    #################################################################################################
    # Misc peripheral configuration
    #################################################################################################
    # This config is required to enable function keys in Keychron K1 keyboard
    environment.etc."modprobe.d/keychron.conf".text = "options hid_apple fnmode=0";
  };
}
