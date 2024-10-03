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
    ( lib.mkIf config.security.sudo.enable {
      security.sudo.extraConfig = ''
        Defaults        lecture=never
      '';
    } )

    ( lib.mkIf config.nix.enable {
      nix = {
        ## Cleanup operations
        # Specify size constraints for nix store
        # Free upto 1G when free space falls below 100M
        extraOptions = ''
          min-free = ${toString (100 * 1024 * 1024)}
          max-free = ${toString (1024 * 1024 * 1024)}
        '';

        # Clean up week old packages
        # NOTE: It is possible that too many initrd disks are created and /boot runs out of space.
        # I suspect the logs wont have any indication of the error. Newer generations would just stop appearing.
        # If this happens, start manually deleting generations.
        gc = {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 7d";
        };

        # Enable flakes system-wide
        settings.experimental-features = [ "nix-command" "flakes" ];
      };
    } )

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

    ( lib.mkIf config.services.xserver.enable {
      services.xserver.excludePackages = [ pkgs.xterm ];
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

    ( lib.mkIf ( config.hardware.steam-hardware.enable &&
                 ! config.installconfig.enable_full_codecoverage_for_test ) {
      nixpkgs.config.allowUnfree = lib.mkDefault true;
    } )

    ( lib.mkIf config.programs.firefox.enable {
      programs.firefox =  {
        languagePacks = [ "en-US" ];
        policies = {
          "DisableFirefoxStudies" = true;
          "DisablePocket" = true;
          "DisableTelemetry" = true;
          "DNSOverHTTPS" = {
            "Enabled" = true;
            "Fallback" = false;
            "Locked" = true;
          };
          "EncryptedMediaExtensions" = {
            "Enabled" = true;
          };
          "ExtensionSettings" = {
            "*" = {
              "blocked_install_message" = "Extension installation blocked, contact administrator!";
              "installation_mode" = "blocked";
            };
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
              "installation_mode" = "force_installed";
              "install_url" = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            };
            "uBlock0@raymondhill.net" = {
              "installation_mode" = "force_installed";
              "install_url" = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            };
          };
          "FirefoxHome" = {
            "Pocket" = false;
            "SponsoredPocket" = false;
            "SponsoredTopSites" = false;
          };
          "FirefoxSuggest" = {
            "WebSuggestions" = false;
            "SponsoredSuggestions" = false;
            "ImproveSuggest" = false;
          };
          "OfferToSaveLogins" = false;
          "UserMessaging" = {
            "ExtensionRecommendations" = false;
            "FeatureRecommendations" = false;
          };
        };
        preferences = {
          "browser.cache.disk.enable" = false;
        };
      };
    } )

    ( lib.mkIf config.programs.chromium.enable {
      # TODO: emit unmaintained warning
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

    ( lib.mkIf config.installconfig.enable_impermanence ( lib.mkMerge [
      ( {
        # File system defines
        fileSystems."/".options = [ "defaults" "size=2G" "mode=755" ];

        environment.persistence."/nix/state" = lib.mkMerge [
          ( {
            hideMounts = true;
            directories = [
              "/etc/nixos"
              "/var/lib/nixos"
              "/var/log"
            ];
            files = [
              "/etc/machine-id"
            ];
          } )

          ( lib.mkIf config.virtualisation.libvirtd.enable {
            directories = [ "/var/lib/libvirt" ];
          } )

          ( lib.mkIf config.services.fprintd.enable {
            directories = [ "/var/lib/fprint" ];
          } )

          ( lib.mkIf config.services.flatpak.enable {
            directories = [ "/var/lib/flatpak" ];
          } )

          ( lib.mkIf config.virtualisation.docker.enable {
            directories = [ "/var/lib/docker" ];
          } )

          ( lib.mkIf config.hardware.bluetooth.enable {
            directories = [ "/var/lib/bluetooth" ];
          } )

          ( lib.mkIf config.networking.networkmanager.enable {
            directories = [ "/etc/NetworkManager/system-connections" ];
          } )

          ( lib.mkIf config.services.openssh.enable {
            files = [
              "/etc/ssh/ssh_host_rsa_key"
              "/etc/ssh/ssh_host_rsa_key.pub"
              "/etc/ssh/ssh_host_ed25519_key"
              "/etc/ssh/ssh_host_ed25519_key.pub"
            ];
          } )
        ];
      } )

      ( lib.mkIf config.services.tailscale.enable {
        # https://forum.tailscale.com/t/persist-your-tailscale-darlings/904/4
        systemd.services.tailscaled.serviceConfig.BindPaths = "/nix/state/var/lib/tailscale:/var/lib/tailscale";

        # Ensure that /nix/state/var/lib/tailscale exists.
        systemd.tmpfiles.rules = [
          "d /nix/state/var/lib/tailscale 0700 root root"
        ];
      } )
    ] ) )
  ];
}