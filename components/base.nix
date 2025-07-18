{ config, lib, pkgs, ... }:
let
  updatescript =
    pkgs.writeShellScriptBin "nixos-update"
      "nixos-rebuild boot --upgrade --option tarball-ttl 10";
  upgradescript = pkgs.writeShellScriptBin "nixos-upgrade"
    "nix-channel --add https://channels.nixos.org/nixos-$1 nixos";
in
{
  options.installconfig = {
    workstation_components =
      lib.mkEnableOption "Configure the machine to be a workstation";
    devtools = lib.mkEnableOption "Tools for development";
  };

  config = lib.mkMerge [
    ({
      #################################################################################################
      # Boot and timezone configuration
      #################################################################################################

      boot.loader.grub.enable = false;
      time.timeZone = lib.mkDefault "America/New_York";

      #################################################################################################
      # Network configuration
      #################################################################################################

      # Disable IPV6 https://github.com/NixOS/nixpkgs/issues/87802
      boot.kernelParams = [ "ipv6.disable=1" ];
      networking.enableIPv6 = false;

      # Default nameservers
      networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

      #################################################################################################
      # Default programs and services
      #################################################################################################

      system.autoUpgrade.enable = true;

      services = {
        # Networking/remote access services
        openssh.enable = true;
        tailscale.enable = true;
      };

      programs = {
        # Git is required for pulling nix configuration
        git = {
          enable = true;
          lfs.enable = true;
        };

        # Custom settings are easier to apply if package is enabled systemwide
        tmux.enable = true;

        # Enable gnupg
        gnupg.agent.enable = true;
      };

      environment = {
        sessionVariables = {
          # Make running non installed commands interactive and painless
          NIX_AUTO_RUN = 1;
          NIX_AUTO_RUN_INTERACTIVE = 1;
        };

        shellAliases = {
          reboot_to_firmware = "systemctl reboot --firmware-setup";
          debug_kernel_interrupts =
            "watch -n0.1 -d --no-title cat /proc/interrupts";
        };

        systemPackages = with pkgs; [
          # Utility update/upgrade scripts
          updatescript
          upgradescript
          # Packages for dotfile management
          pinentry
          yadm
        ];
      };

      users.mutableUsers = false;
    })

    (lib.mkIf config.installconfig.devtools {
      environment.systemPackages = with pkgs; [
        clang
        deno
        gtest
        meson
        ninja
        pkg-config
        rustup
      ];
    })

    (lib.mkIf config.installconfig.workstation_components {
      # Enable auto updating timezone information
      services.tzupdate.enable = true;

      services.xserver = {
        # Enable the X11 windowing system.
        enable = true;

        # Enable the GNOME Desktop Environment.
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };

      # disable pulseaudio and enable pipewire
      services = {
        pulseaudio.enable = lib.mkForce false;
        pipewire = {
          enable = true;
          pulse.enable = true;
          alsa.enable = true;
        };
      };

      # Enable flatpak on workstation machines.
      services.flatpak.enable = true;

      # Enable chromium
      programs.chromium.enable = true;

      # IDE configuration
      environment.systemPackages = with pkgs; [
        (vscode-with-extensions.override {
          vscode = vscodium;
          vscodeExtensions = (
            [
              vscode-extensions.alefragnani.bookmarks
            ] ++ vscode-utils.extensionsFromVscodeMarketplace [{
              name = "gitstash";
              publisher = "arturock";
              version = "5.2.0";
              sha256 = "sha256-IVWb4tXD+5YbqJv4Ajp0c3UvYdMzh83NlyiYpndclEY=";
            }]
          ) ++ lib.optionals config.installconfig.devtools (
            [
              vscode-extensions.denoland.vscode-deno
              vscode-extensions.jnoortheen.nix-ide
              vscode-extensions.rust-lang.rust-analyzer
              vscode-extensions.vadimcn.vscode-lldb
            ] ++ vscode-utils.extensionsFromVscodeMarketplace [{
              name = "geminicodeassist";
              publisher = "Google";
              version = "2.37.0";
              sha256 = "sha256-oJmWxdEN2uTo5Ms3WFrTbosd+DKQq4jrOtPChQjaWe0=";
            }]
          );
        })
      ];

      #################################################################################################
      # Misc peripheral configuration
      #################################################################################################
      hardware.steam-hardware.enable = true;
      services.udev.packages = [ pkgs.android-udev-rules ];
      # Allow workstations to pass usb devices to virtual machines
      virtualisation.spiceUSBRedirection.enable = true;

      # Enable razer configurator for Viper V3 Hyperspeed mouse
      hardware.openrazer.enable = true;

      # This config is required to enable function keys in Keychron K1 keyboard
      environment.etc."modprobe.d/keychron.conf".text =
        "options hid_apple fnmode=0";

      # Add keyd for misc keyboard configuration
      services.keyd.enable = true;
    })
  ];
}
