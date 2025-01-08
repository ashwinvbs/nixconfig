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
  radpassFile = "/etc/nixos/secrets/radpass.txt";
  homePermanence = {
    directories = [
      ".android"
      ".config"
      ".local"
      ".mozilla"
      ".var/app"
      ".vscode-oss"
      "Documents"
      "Downloads"
      "Music"
      "Workspaces"
      {
        directory = ".ssh";
        mode = "0700";
      }
    ];
    files = [ ".bash_history" ".bashrc" ".gitconfig" ];
  };
in
{
  options.installconfig = {
    users.allow_rad = lib.mkEnableOption "Adds radhulya as a normal user";
  };

  config = lib.mkMerge [
    (lib.mkIf config.security.sudo.enable {
      security.sudo.extraConfig = ''
        Defaults        lecture=never
      '';
    })

    (lib.mkIf config.nix.enable {
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
    })

    (lib.mkIf config.system.autoUpgrade.enable (lib.mkMerge [
      ({
        system.autoUpgrade = {
          randomizedDelaySec = "30min";
          flags = [
            "--option"
            "tarball-ttl"
            "0"
          ];
          dates = "daily";
        };
      })

      (lib.mkIf config.installconfig.workstation_components {
        system.autoUpgrade.operation = "boot";
      })

      (lib.mkIf (!config.installconfig.workstation_components) {
        system.autoUpgrade = {
          allowReboot = true;
          rebootWindow = {
            lower = "01:00";
            upper = "03:00";
          };
        };
      })
    ]))

    (lib.mkIf config.services.openssh.enable {
      services.openssh.settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    })

    (lib.mkIf config.programs.tmux.enable {
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
    })

    (lib.mkIf config.services.xserver.enable {
      services.xserver.excludePackages = [ pkgs.xterm ];
    })

    (lib.mkIf config.services.xserver.desktopManager.gnome.enable {
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
        nautilus
      ];

      programs.file-roller.enable = true;

      # VTE shell integration for gnome-console
      programs.bash.vteIntegration = true;

      # Override default mimeapps for nautilus
      environment.sessionVariables.XDG_DATA_DIRS = [ "${mimeAppsList}/share" ];
    })

    (lib.mkIf config.programs.firefox.enable {
      programs.firefox = {
        languagePacks = [ "en-US" ];
        policies = {
          "DisableFirefoxStudies" = true;
          "DisablePocket" = true;
          "DisableTelemetry" = true;
          "DNSOverHTTPS" = {
            "Enabled" = false;
            "Locked" = true;
          };
          "EncryptedMediaExtensions" = { "Enabled" = true; };
          "ExtensionSettings" = {
            "*" = {
              "blocked_install_message" =
                "Extension installation blocked, contact administrator!";
              "installation_mode" = "blocked";
            };
            "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
              "installation_mode" = "force_installed";
              "install_url" =
                "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            };
            "uBlock0@raymondhill.net" = {
              "installation_mode" = "force_installed";
              "install_url" =
                "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
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
        preferences = { "browser.cache.disk.enable" = false; };
      };
    })

    (lib.mkIf config.programs.chromium.enable {
      # TODO: emit unmaintained warning
      environment.systemPackages = with pkgs;
        [
          # programs.chromium.enable = true only enables policy o.0 :| ???
          google-chrome
        ];
      nixpkgs.config = lib.mkDefault {
        allowUnfree = true;
      };

      programs.chromium.extraOpts = {
        # TODO: Default Search Provider

        # Extensions
        "ExtensionInstallBlocklist" = [ "*" ];
        "ExtensionInstallForcelist" = [
          "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
          "apjcbfpjihpedihablmalmbbhjpklbdf" # AdGuard AdBlocker
        ];

        # TODO: Generative AI

        # Google Cast
        "EnableMediaRouter" = false;

        # TODO: Legacy Browser Support - use for freetube

        # Miscellaneous
        "AdvancedProtectionAllowed" = false;
        "AllowDinosaurEasterEgg" = false;
        "AutofillAddressEnabled" = false;
        "AutofillCreditCardEnabled" = false;
        "BackgroundModeEnabled" = true;
        "BlockThirdPartyCookies" = true;
        "BrowserLabsEnabled" = false;
        "BrowserNetworkTimeQueriesEnabled" = false;
        "GoogleSearchSidePanelEnabled" = false;
        "HideWebStoreIcon" = true;
        "IntensiveWakeUpThrottlingEnabled" = true;
        "MetricsReportingEnabled" = false;
        "PaymentMethodQueryEnabled" = false;
        "ProfilePickerOnStartupAvailability" = 1;
        "PromotionsEnabled" = false;
        "RemoteDebuggingAllowed" = false;
        "SharedClipboardEnabled" = false;
        "ShoppingListEnabled" = false;
        "ShowAppsShortcutInBookmarkBar" = false;
        "ShowFullUrlsInAddressBar" = true;
        "SpellCheckServiceEnabled" = false;
        "UrlKeyedAnonymizedDataCollectionEnabled" = false;

        # Password manager
        "PasswordManagerEnabled" = false;

        # Printing
        "CloudPrintProxyEnabled" = false;

        # Privacy Sandbox policies
        "PrivacySandboxAdMeasurementEnabled" = false;
        "PrivacySandboxAdTopicsEnabled" = false;
        "PrivacySandboxPromptEnabled" = false;
        "PrivacySandboxSiteEnabledAdsEnabled" = false;

        # Related Website Sets
        "RelatedWebsiteSetsEnabled" = false;

        # Remote access
        "RemoteAccessHostAllowRemoteAccessConnections" = false;
        "RemoteAccessHostAllowRemoteSupportConnections" = false;

        # Safe Browsing
        "SafeBrowsingDeepScanningEnabled" = false;
        "SafeBrowsingExtendedReportingEnabled" = false;
        "SafeBrowsingProtectionLevel" = 1;
        "SafeBrowsingSurveysEnabled" = false;

        # Startup, Home page and New Tab page
        "HomepageIsNewTabPage" = true;
        "ShowHomeButton" = false;
      };
    })

    (lib.mkIf config.virtualisation.docker.enable {
      users.groups.docker.members = [ "ashwin" ];
    })

    (lib.mkIf config.virtualisation.libvirtd.enable {
      users.groups.libvirtd.members = [ "ashwin" ];
    })

    (lib.mkMerge [
      ({
        # File system defines
        fileSystems."/".options = [ "defaults" "size=2G" "mode=755" ];

        environment.persistence."/nix/state" = lib.mkMerge [
          ({
            hideMounts = true;
            directories = [ "/etc/nixos" "/var/lib/nixos" "/var/log" ];
            files = [ "/etc/machine-id" ];
            users.ashwin = homePermanence;
          })

          (lib.mkIf config.virtualisation.libvirtd.enable {
            directories = [ "/var/lib/libvirt" ];
          })

          (lib.mkIf config.services.fprintd.enable {
            directories = [ "/var/lib/fprint" ];
          })

          (lib.mkIf config.services.flatpak.enable {
            directories = [ "/var/lib/flatpak" ];
          })

          (lib.mkIf config.virtualisation.docker.enable {
            directories = [ "/var/lib/docker" ];
          })

          (lib.mkIf config.hardware.bluetooth.enable {
            directories = [ "/var/lib/bluetooth" ];
          })

          (lib.mkIf config.networking.networkmanager.enable {
            directories = [ "/etc/NetworkManager/system-connections" ];
          })

          (lib.mkIf config.services.openssh.enable {
            files = [
              "/etc/ssh/ssh_host_rsa_key"
              "/etc/ssh/ssh_host_rsa_key.pub"
              "/etc/ssh/ssh_host_ed25519_key"
              "/etc/ssh/ssh_host_ed25519_key.pub"
            ];
          })
        ];
      })

      (lib.mkIf config.services.tailscale.enable {
        # https://forum.tailscale.com/t/persist-your-tailscale-darlings/904/4
        systemd.services.tailscaled.serviceConfig.BindPaths =
          "/nix/state/var/lib/tailscale:/var/lib/tailscale";

        # Ensure that /nix/state/var/lib/tailscale exists.
        systemd.tmpfiles.rules =
          [ "d /nix/state/var/lib/tailscale 0700 root root" ];
      })
    ])

    (lib.mkIf config.installconfig.users.allow_rad {
      users.users.radhulya = {
        isNormalUser = true;
        description = "Radhulya Thirumalaisamy";
        hashedPassword =
          if builtins.pathExists radpassFile then
            lib.strings.fileContents radpassFile
          else
            null;
      };

      environment.persistence."/nix/state" = {
        users.radhulya = homePermanence;
      };
    })
  ];
}
