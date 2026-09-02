{
  description = "PinePhone A64 Provisioner OS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    mobile-nixos = {
      url = "github:nixos/mobile-nixos";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      mobile-nixos,
    }:
    let
      pkgs-x86 = nixpkgs.legacyPackages.x86_64-linux;

      sharedConfig =
        { lib, pkgs, ... }:
        let
          # Dedicated script to execute the flash and trigger UI popups
          flasherScript = pkgs.writeShellScript "pinephone-flasher" ''
            IMG=$(ls /image/*.img 2>/dev/null | head -n 1)
            if [ -n "$IMG" ]; then
              ${pkgs.libnotify}/bin/notify-send -u critical "System Installer" "Flashing $IMG to eMMC. DO NOT REBOOT."
              ${pkgs.coreutils}/bin/dd if="$IMG" of=/dev/mmcblk2 bs=8M oflag=sync
              ${pkgs.libnotify}/bin/notify-send -u critical "System Installer" "Flashing complete! Safe to reboot."
            fi
          '';
        in
        {
          system.stateVersion = "26.05";

          # --- UI & Mobile Environment ---
          services.xserver.enable = true;
          services.xserver.desktopManager.phosh = {
            enable = true;
            user = "isha";
            group = "users";
          };

          services.displayManager.gdm.enable = true;
          services.displayManager.autoLogin = {
            enable = true;
            user = "isha";
          };

          # Workaround: Prevent getty from fighting GDM over tty1 on boot
          systemd.services."getty@tty1".enable = false;

          # --- Dconf Overrides for Screen Lock ---
          programs.dconf = {
            enable = true;
            profiles.user.databases = [
              {
                settings = {
                  "mobi/phosh/shell".require-unlock = false;
                  "mobi/phosh".lockscreen-enabled = false;
                  "org/gnome/desktop/screensaver".lock-enabled = false;
                  "org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 120;
                };
              }
            ];
          };

          # --- Target Users ---
          users.users.isha = {
            isNormalUser = true;
            extraGroups = [
              "video"
              "audio"
            ];
            initialPassword = "1234";
          };

          users.users.ashwin = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            initialPassword = "1234";
          };

          networking.hostName = "pinephone";

          # --- Packages ---
          environment.systemPackages = with pkgs; [
            gnome-console
            lollypop
            megapixels
            loupe
            libnotify # Required to display flash progress alerts
          ];

          # --- Device rules for camera app ---
          services.udev.packages = [ pkgs.megapixels ];

          # --- Flasher Sudo Bypass Rule (ashwin) ---
          security.sudo.extraRules = [
            {
              users = [ "ashwin" ];
              commands = [
                {
                  command = "${flasherScript}";
                  options = [ "NOPASSWD" ];
                }
              ];
            }
          ];

          # --- Auto-Resize Root Partition ---
          systemd.services.resize-root = {
            description = "Resize root partition to fill physical storage";
            wantedBy = [ "multi-user.target" ];
            after = [ "local-fs.target" ];
            path = with pkgs; [
              cloud-utils
              e2fsprogs
              util-linux
            ];
            script = ''
              ROOT_DEV=$(findmnt -n -o SOURCE /)

              # Match PinePhone SD card (/dev/mmcblk0) or eMMC (/dev/mmcblk2)
              if [[ $ROOT_DEV =~ ^(/dev/mmcblk[0-9]+)p([0-9]+)$ ]]; then
                DISK="''${BASH_REMATCH[1]}"
                PART="''${BASH_REMATCH[2]}"
                
                # Attempt to grow the partition table (returns 1 if already max size, ignored by || true)
                growpart "$DISK" "$PART" || true
                
                # Resize the ext4 filesystem to match the new partition bounds
                resize2fs "$ROOT_DEV" || true
              fi
            '';
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
          };

          # --- Dynamic Application Visibility ---
          # 1. Watch /image for any filesystem changes
          systemd.paths.image-watcher = {
            wantedBy = [ "multi-user.target" ];
            pathConfig = {
              PathChanged = "/image";
              MakeDirectory = true;
            };
          };

          # 2. Trigger desktop entry creation or deletion
          systemd.services.image-watcher = {
            wantedBy = [ "multi-user.target" ];
            after = [ "local-fs.target" ];
            script = ''
              DESKTOP_DIR="/home/ashwin/.local/share/applications"
              DESKTOP_FILE="$DESKTOP_DIR/pinephone-flasher.desktop"

              mkdir -p "$DESKTOP_DIR"
              chown -R ashwin:users "/home/ashwin/.local"

              if ls /image/*.img 1> /dev/null 2>&1; then
                cat <<EOF > "$DESKTOP_FILE"
              [Desktop Entry]
              Name=Flash OS Image
              Exec=sudo ${flasherScript}
              Icon=drive-harddisk
              Type=Application
              Terminal=false
              EOF
                chown ashwin:users "$DESKTOP_FILE"
              else
                rm -f "$DESKTOP_FILE"
              fi
            '';
            serviceConfig.Type = "oneshot";
          };
        };

      eval-pinephone = import "${mobile-nixos}/lib/eval-with-configuration.nix" {
        system = "aarch64-linux";
        device = "pine64-pinephone";
        configuration = [ sharedConfig ];
      };

      eval-vm = import "${mobile-nixos}/lib/eval-with-configuration.nix" {
        system = "x86_64-linux";
        device = "uefi-x86_64";
        configuration = [ sharedConfig ];
      };

      # Script handling image referencing, overlay recreation, and standard QEMU execution
      vm-runner = pkgs-x86.writeShellScriptBin "run-pinephone-vm" ''
        set -e
        IMAGE_PATH="$(echo ${eval-vm.outputs.default}/*.img)"
        OVERLAY="/tmp/pinephone-overlay.qcow2"

        echo "Recreating clean QEMU overlay at $OVERLAY..."
        rm -f "$OVERLAY"
        ${pkgs-x86.qemu}/bin/qemu-img create -f qcow2 -b "$IMAGE_PATH" -F raw "$OVERLAY"

        echo "Booting PinePhone VM..."
        exec ${pkgs-x86.qemu}/bin/qemu-system-x86_64 \
          -enable-kvm \
          -m 2048 \
          -smp 4 \
          -device virtio-vga \
          -display gtk,gl=on \
          -bios ${pkgs-x86.OVMF.fd}/FV/OVMF.fd \
          -drive file="$OVERLAY",format=qcow2,if=virtio
      '';
    in
    {
      packages.x86_64-linux.default = eval-pinephone.outputs.default;
      packages.aarch64-linux.default = eval-pinephone.outputs.default;

      apps.x86_64-linux.vm = {
        type = "app";
        program = "${vm-runner}/bin/run-pinephone-vm";
      };
    };
}
