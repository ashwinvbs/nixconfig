#!/usr/bin/env bash
set -euo pipefail

# Default to current directory if $1 is unset/empty, store in variable
ARG_PATH="${1:-.}"

# Validate: must be a file OR a directory containing default.nix
if [[ ! -f "$ARG_PATH" ]] && [[ ! ( -d "$ARG_PATH" && -f "$ARG_PATH/default.nix" ) ]]; then
    echo "Error: '$ARG_PATH' must be a file or a directory containing default.nix" >&2
    exit 1
fi

CONFIGDIR=$(readlink -f "$ARG_PATH")

echo "Building a vm to test $CONFIGDIR"

MACHINE_NAME="test_machine"

TEMPDIR=$(mktemp -d)
trap 'rm -rf $TEMPDIR' EXIT

cd "$TEMPDIR"

echo "{ config, lib, pkgs, ... }:
{
  imports = [ $CONFIGDIR ];

  security.sudo.extraConfig = \"user  ALL=NOPASSWD:/run/current-system/sw/bin/poweroff\";

  networking.hostName = \"$MACHINE_NAME\";
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ \"wheel\" ];
    password = \"password\";
  };

  # Disable background indexing to prevent boot lockups
  services.gnome.localsearch.enable = lib.mkForce false;

  services.xserver = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  services.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = \"user\";
  };

  # All overrides MUST go inside vmVariant to be picked up by system.build.vm
  virtualisation.vmVariant.virtualisation = {

    # Build the fat image securely into the host /nix/store and uses a tiny overlay in /tmp.
    useBootLoader = true;

    memorySize = 6144; # 6 GB RAM
    cores = 8;         # 8 CPU Cores

    qemu.options = [
        # Generic AMD server processor profile. Hides the exact CPU model
        # but retains modern instruction sets (AVX2) for acceptable performance.
        \"-cpu host,model-id=Common-KVM-Processor,family=15,model=6,stepping=1\"

        # Standard virtual GPU. Forces the guest to use software rendering (llvmpipe).
        \"-vga virtio\"

        # Basic GTK window without host OpenGL hooks.
        \"-display gtk\"
    ];

    sharedDirectories = lib.mkForce {
      xchg = {
        source = ''\"\$TMPDIR\"/xchg'';
        securityModel = \"none\";
        target = \"/tmp/xchg\";
      };
    };
  };
}
" > ./$MACHINE_NAME.nix

echo "Building $(readlink -f ./$MACHINE_NAME.nix)"

# CRITICAL: Build config.system.build.vm
# Do NOT build vmWithBootLoader, as that ignores vmVariant.
nix-build '<nixpkgs/nixos>' \
  -A config.system.build.vm \
  -I "nixpkgs=channel:nixos-$(nixos-version | cut -d. -f1,2)" \
  -I nixos-config=./$MACHINE_NAME.nix

"./result/bin/run-$MACHINE_NAME-vm"
