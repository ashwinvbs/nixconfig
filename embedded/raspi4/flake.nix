{
  pkgs ? import <nixpkgs> { },
}:

let
  eval = import "${pkgs.path}/nixos" {
    configuration =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      with lib;

      let
        make-ext4-fs =
          {
            volumeLabel,
            populateImageCommands ? "",
          }:
          pkgs.stdenv.mkDerivation {
            name = "${volumeLabel}.ext4.img";
            nativeBuildInputs = with pkgs; [
              e2fsprogs
              libfaketime
              fakeroot
            ];
            buildCommand = ''
              mkdir -p ./files

              # populateImageCommands fills the current working dir.
              (cd ./files && ${populateImageCommands})

              # Automatically calculate required image size
              # Size = apparent size + 15% overhead + 50MB padding
              bytes=$(du -s -B1 ./files | awk '{print $1}')
              size=$(($bytes + ($bytes * 15 / 100) + 50 * 1024 * 1024))

              truncate -s $size ./ext4.img

              # Ensure deterministic builds
              export SOURCE_DATE_EPOCH=1
              export FAKETIME="1970-01-01 00:00:01"

              # Format the sparse file and populate it deterministically
              faketime -f "$FAKETIME" fakeroot mkfs.ext4 -L ${volumeLabel} -d ./files ./ext4.img

              export EXT2FS_NO_MTAB_OK=yes
              # I have ended up with corrupted images sometimes, I suspect that happens when the build machine's disk gets full during the build.
              if ! fsck.ext4 -n -f ./ext4.img; then
                echo "--- Fsck failed for EXT4 image ${volumeLabel} of $bytes bytes ---"
                cat errorlog
                return 1
              fi

              # We may want to shrink the file system and resize the image to
              # get rid of the unnecessary slack here--but see
              # https://github.com/NixOS/nixpkgs/issues/125121 for caveats.

              # shrink to fit
              resize2fs -M ./ext4.img

              # Add 16 MebiByte to the current_size
              new_size=$(dumpe2fs -h ./ext4.img | awk -F: \
                '/Block count/{count=$2} /Block size/{size=$2} END{print (count*size+16*2**20)/size}')

              resize2fs ./ext4.img $new_size

              # Compress or output as raw image
              mv ./ext4.img $out
            '';
          };

        make-vfat-fs =
          {
            volumeLabel,
            populateImageCommands ? "",
          }:
          pkgs.stdenv.mkDerivation {
            name = "${volumeLabel}.vfat.img";
            nativeBuildInputs = with pkgs; [
              dosfstools
              mtools
              libfaketime
              fakeroot
            ];
            buildCommand = ''
              mkdir -p ./files

              # populateImageCommands fills the current working dir.
              (cd ./files && ${populateImageCommands})

              # Automatically calculate required image size
              dir_bytes=$(du -s -B1 ./files | awk '{print $1}')
              # Add 15% buffer
              dir_bytes_with_buffer=$((dir_bytes + (dir_bytes * 15 / 100)))
              min_bytes=$((30 * 1024 * 1024))

              # Select the maximum of the two using double brackets
              if [[ "$dir_bytes_with_buffer" -gt "$min_bytes" ]]; then
                size=$dir_bytes_with_buffer
              else
                size=$min_bytes
              fi

              # Create the image file
              truncate -s $size ./vfat.img

              # Format the created file
              mkfs.vfat --invariant -n ${volumeLabel} ./vfat.img

              # Populate the image
              cd files
              for d in $(find . -type d -mindepth 1 | sort); do
                faketime "2000-01-01 00:00:00" mmd -i ../vfat.img "::/$d"
              done
              for f in $(find . -type f | sort); do
                mcopy -pvm -i ../vfat.img "$f" "::/$f"
              done
              cd ..

              # Verify
              fsck.vfat -vn ./vfat.img

              # Output raw image
              mv ./vfat.img $out
            '';
          };

        nixPartition = make-ext4-fs {
          volumeLabel = "NIX_SYSTEM";
          populateImageCommands = ''
            mkdir ./store

            # Retrieve the closure of all required store paths
            closureInfo=${pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; }}

            # Copy all store paths into the image staging area
            xargs -I % cp -a --reflink=auto % -t ./store/ < $closureInfo/store-paths
          '';
        };

        bootPartition = make-ext4-fs {
          volumeLabel = "NIX_BOOT";
          populateImageCommands = ''
            ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d .
          '';
        };

        firmwarePartition = make-vfat-fs {
          volumeLabel = "FIRMWARE";
          populateImageCommands = ''
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bootcode.bin .
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/fixup*.dat .
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/start*.elf .
            cp ${pkgs.writeText "config.txt" ''
              [pi3]
              kernel=u-boot-rpi3.bin
              core_freq=250
              [pi02]
              kernel=u-boot-rpi3.bin
              [pi4]
              kernel=u-boot-rpi4.bin
              enable_gic=1
              armstub=armstub8-gic.bin
              disable_overscan=1
              arm_boost=1
              [cm4]
              otg_mode=1
              [all]
              arm_64bit=1
              enable_uart=1
              avoid_warnings=1
            ''} config.txt
            cp ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin                             u-boot-rpi3.bin
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-2-b.dtb       .
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-3-b.dtb       .
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-3-b-plus.dtb  .
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-cm3.dtb       .
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-zero-2.dtb    .
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2710-rpi-zero-2-w.dtb  .
            cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin                             u-boot-rpi4.bin
            cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin                          armstub8-gic.bin
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb       .
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-400.dtb       .
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-cm4.dtb       .
            cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-cm4s.dtb      .
            find . -exec touch --date=2000-01-01 {} +
          '';
        };
      in
      {
        config = {
          nixpkgs.hostPlatform = "aarch64-linux";

          services.pipewire = {
            enable = true;
            systemWide = true; # Handles the service user and systemd units for you
            alsa.enable = true;
            wireplumber.enable = true;

            # Inject your ROC config into the global search path
            extraConfig.pipewire."99-roc-source" = {
              "context.modules" = [
                {
                  name = "libpipewire-module-roc-source";
                  args = {
                    "source.name" = "remote soundcard";
                    "source.props.node.name" = "roc-source";
                    # Might need tuning if crackling/stuttering is observed
                    "sess.latency.msec" = "100";
                  };
                }
              ];
            };
          };

          # Global environment variable for ease of using wpctl
          environment.variables = {
            PIPEWIRE_RUNTIME_DIR = "/run/pipewire";
          };

          # Ensure the pipewire user has a place to save settings
          # This prevents WirePlumber from complaining about missing state directories.
          systemd.services.wireplumber.serviceConfig.StateDirectory = "wireplumber";
          systemd.services.pipewire.serviceConfig.StateDirectory = "pipewire";

          # Open the ROC ports
          networking.firewall = {
            allowedTCPPorts = [
              10001
              10002
              10003
            ];
            allowedUDPPorts = [
              10001
              10002
              10003
            ];
          };

          # Ensure real-time priority works for the system-wide service
          security.rtkit.enable = true;

          # One shot service to enumerate audio hardware and set output volume to 100%
          systemd.services.pw-init-volume = {
            description = "Initialize PipeWire Volume and Hardware Enumeration";
            after = [ "wireplumber.service" ];
            wantedBy = [ "multi-user.target" ];

            # Run once, then exit
            serviceConfig = {
              Type = "oneshot";
              User = "pipewire"; # Run as the system-wide pipewire user
              Environment = "PIPEWIRE_RUNTIME_DIR=/run/pipewire";
              RemainAfterExit = true;
            };

            # 1. Wait a few seconds for hardware discovery
            # 2. Set volume to 100%
            # 3. Unmute
            script = ''
              ${pkgs.coreutils}/bin/sleep 2
              ${pkgs.wireplumber}/bin/wpctl status
              ${pkgs.coreutils}/bin/sleep 2
              ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0
              ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            '';
          };

          networking.hostName = "raspi";

          environment.systemPackages = with pkgs; [ ];
          nix.enable = false;

          # users.users.test = {
          #   password = "password";
          #   isNormalUser = true;
          #   extraGroups = [ "wheel" ];
          # };

          boot.supportedFilesystems = [
            "ext4"
            "vfat"
          ];

          boot.loader.grub.enable = false;
          boot.loader.generic-extlinux-compatible.enable = true;
          boot.consoleLogLevel = mkDefault 7;
          boot.kernelParams = [
            "console=ttyS0,115200n8"
            "console=ttyAMA0,115200n8"
            "console=tty0"
          ];

          fileSystems = {
            "/boot/firmware" = {
              device = "/dev/disk/by-label/FIRMWARE";
              fsType = "vfat";
              options = [
                "nofail"
                "noauto"
                "ro"
              ];
            };
            "/boot" = {
              device = "/dev/disk/by-label/NIX_BOOT";
              fsType = "ext4";
              options = [ "ro" ];
            };
            "/nix" = {
              device = "/dev/disk/by-label/NIX_SYSTEM";
              fsType = "ext4";
              options = [ "ro" ];
            };
            "/" = {
              device = "none";
              fsType = "tmpfs";
              options = [
                "defaults"
                "size=512M"
                "mode=755"
              ];
            };
          };

          system.nixos.tags = [ "sd-card" ];
          system.build.image = pkgs.callPackage (
            {
              stdenv,
              dosfstools,
              e2fsprogs,
              mtools,
              libfaketime,
              util-linux,
            }:
            stdenv.mkDerivation {
              name = "nixos-image-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.img";
              nativeBuildInputs = [
                dosfstools
                e2fsprogs
                libfaketime
                mtools
                util-linux
              ];
              buildCommand = ''
                                  mkdir -p $out
                                  export img=$out/nixos-image-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.img
                                  gapSize=$((8 * 1024 * 1024))

                                  gapSizeBlocks=$((gapSize / 512))
                                  firmwareSizeBlocks=$(du -B 512 --apparent-size "${firmwarePartition}" | awk '{ print $1 }')
                                  bootSizeBlocks=$(du -B 512 --apparent-size "${bootPartition}" | awk '{ print $1 }')
                                  systemSizeBlocks=$(du -B 512 --apparent-size "${nixPartition}" | awk '{ print $1 }')

                                  imageSize=$((systemSizeBlocks * 512 + bootSizeBlocks * 512 + firmwareSizeBlocks * 512 + gapSize))
                                  truncate -s $imageSize $img

                                  sfdisk --no-reread --no-tell-kernel $img <<EOF
                label: dos
                label-id: 0x2178694e
                start=$((gapSizeBlocks)), size=$firmwareSizeBlocks, type=b
                start=$((gapSizeBlocks + firmwareSizeBlocks)), size=$bootSizeBlocks, type=83, bootable
                start=$((gapSizeBlocks + firmwareSizeBlocks + bootSizeBlocks)), type=83
                EOF

                                  eval $(partx $img -o START,SECTORS --nr 1 --pairs)
                                  dd conv=notrunc if="${firmwarePartition}" of=$img seek=$START count=$SECTORS
                                  eval $(partx $img -o START,SECTORS --nr 2 --pairs)
                                  dd conv=notrunc if="${bootPartition}" of=$img seek=$START count=$SECTORS
                                  eval $(partx $img -o START,SECTORS --nr 3 --pairs)
                                  dd conv=notrunc if="${nixPartition}" of=$img seek=$START count=$SECTORS
              '';
            }
          ) { };
        };
      };
  };
in
eval.config.system.build.image
