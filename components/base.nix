{ config, lib, pkgs, ... }:

let ashpassFile = "/etc/nixos/secrets/ashpass.txt";
in {
  options.installconfig = {
    workstation_components =
      lib.mkEnableOption "Configure the machine to be a workstation";
    devtools = {
      cpp = lib.mkEnableOption "Tools for c/cpp development";
      nix = lib.mkEnableOption "Tools for nix development";
      rust = lib.mkEnableOption "Tools for rust development";
    };
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

        # TODO: Attempt to do this with options instead of explicit packages
        systemPackages = with pkgs; [ pinentry yadm ];
      };

      users = {
        mutableUsers = false;

        users.ashwin = {
          isNormalUser = true;
          description = "Ashwin Balasubramaniyan";
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBovRDhgavqQPYZYMg70tBP3Ibs1o2qSHSAgz4nW89BQwaosDYvmSK0QvT+J8hDVyvIXyaaHMzHONGavMDLVPhUwe1xt6XzrrFNfpZmquLyP9xMRZkxca/c1ZQpD3pL+n7yvY8DMn+6o6B3LPkwYZqbxPlernS1BYQjQbVBMFrkbMzFtacc+GM+fwku2BueOQuNMlrAKdQBTuDLaMlUQyws0CI9PgbB2NSzsmWWohz/r2nWYZmtVAYAjjdRDuoWgL+sUrCQiiDawctHVNHFfkHK1stY3ywD6FOxnm0tvdX8J0ojdCGZdC/LxdxAfdpbN7VmBM9Gw+uyg/ha6LAXaMFEENTYE6JgaWROJNIULHFq2184lSH0P5MVltcywRSvblZZ1vzVwMFrt5HCrJpRa+ROP/HnSUjzN1BmfJMepEAPQTiXSzRQgo0ymX14Oft95w5m+Q5dV0uhuXtSO6ao66EAXcqgSMChUuqqX7MBIu9xxErezfRgesTJOgvRJrtvUk="
          ];
          hashedPassword =
            if builtins.pathExists ashpassFile then
              lib.strings.fileContents ashpassFile
            else
              null;
        };
      };
    })

    (lib.mkIf config.installconfig.devtools.cpp {
      environment.systemPackages = with pkgs; [ clang gtest meson ninja pkg-config ];
    })

    (lib.mkIf config.installconfig.devtools.rust {
      environment.systemPackages = with pkgs; [ cargo clang pkg-config rustc ];
    })

    (lib.mkIf config.installconfig.workstation_components {
      services.xserver = {
        # Enable the X11 windowing system.
        enable = true;

        # Enable the GNOME Desktop Environment.
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };

      # disable pulseaudio and enable pipewire
      hardware.pulseaudio.enable = lib.mkForce false;
      services.pipewire = {
        enable = true;
        pulse.enable = true;
        alsa.enable = true;
      };

      # Enable flatpak on workstation machines.
      services.flatpak.enable = true;

      # Enable chromium
      programs.chromium.enable = true;

      # IDE configuration
      environment.systemPackages = with pkgs; [
        (vscode-with-extensions.override {
          vscode = vscodium;
          vscodeExtensions = with vscode-extensions; [
            alefragnani.bookmarks
          ] ++ vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "gitstash";
              publisher = "arturock";
              version = "5.1.0";
              sha256 = "sha256-T8uagDYIRdqHxsSjJ2M8LKrWwearKmHYFXx4lopoa9s=";
            }
          ] ++ lib.optionals config.installconfig.devtools.nix [
            vscode-extensions.jnoortheen.nix-ide
          ] ++ lib.optionals config.installconfig.devtools.cpp [
            vscode-extensions.vadimcn.vscode-lldb
          ] ++ lib.optionals config.installconfig.devtools.rust [
            vscode-extensions.vadimcn.vscode-lldb
            vscode-extensions.rust-lang.rust-analyzer
          ];
        })
      ];

      #################################################################################################
      # Misc peripheral configuration
      #################################################################################################
      hardware.steam-hardware.enable = true;
      services.udev.packages = [ pkgs.android-udev-rules ];
      # Above rule spams journal if adbusers group does not exist
      users.groups.adbusers.members = [ "ashwin" ];
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
