#!/usr/bin/env bash

# More safety, by turning some bugs into errors.
set -o pipefail -o noclobber -o nounset

prepare_fake_root() {
    mount -t tmpfs none /mnt
    mkdir -p /mnt/{boot,nix,etc}
}

partition_disks() {
    DISK=$1

    sgdisk -Zog $DISK
    sgdisk -n 0:0:+1G -t 0:ef00 -c 0:nixboot $DISK
    sgdisk -n 0:0:0 -t 0:8300 -c 0:nixsystem $DISK

    sleep 10
}

format_and_mount_boot() {
    mkfs.fat -F 32 -n nixboot /dev/disk/by-partlabel/nixboot

    mount -o uid=0,gid=0,fmask=0077,dmask=0077 /dev/disk/by-partlabel/nixboot /mnt/boot
}

format_and_mount_nix_plain() {
    mkfs.ext4 -F -L nixsystem /dev/disk/by-partlabel/nixsystem

    mount /dev/disk/by-partlabel/nixsystem /mnt/nix
}

format_and_mount_nix_password() {
    cryptsetup luksFormat /dev/disk/by-partlabel/nixsystem
    cryptsetup luksOpen /dev/disk/by-partlabel/nixsystem nixsystem
    mkfs.ext4 -F -L nixsystem /dev/mapper/nixsystem

    mount /dev/mapper/nixsystem /mnt/nix
}

post_disk_ready() {
    mkdir -p /mnt/nix/state/etc/nixos/secrets
    # Need this to sidestep impermanence
    pushd /mnt/etc/
    ln -sf ../nix/state/etc/nixos
    popd
    # Need this so we can have absolute paths for secrets
    pushd /etc/nixos
    ln -sf ../../mnt/nix/state/etc/nixos/secrets
    popd

    echo 'Enter password for user ashwin'
    mkpasswd -m sha-512 >/mnt/etc/nixos/secrets/ashwin_pass.txt

    nixos-generate-config --root /mnt

    cat >|/mnt/etc/nixos/configuration.nix <<EOL
{ ... }:
let
nixconfig = builtins.fetchGit {
  url = "https://github.com/ashwinvbs/nixconfig.git";
  ref = "main";
};
in
{
imports =
  [
    ./hardware-configuration.nix
    "\${nixconfig}"
    # (import "\${nixconfig}/utils/adduser.nix" { shortname = "user"; fullname = "User user"; persist = { directories = [ "." ]; }; })
  ];
  networking.hostName = "$MACHINE";
}
EOL

    cd /mnt/etc/nixos
}

## Function declarations end. Script start.

getopt --test >/dev/null
if [[ $? -ne 4 ]]; then
    echo '`getopt --test` failed in this environment.'
    exit 1
fi

# Use of getopts from https://stackoverflow.com/a/29754866
LONGOPTS=disk:,machine:,encryption:
OPTIONS=d:m:e:

PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

DISK=""
MACHINE=""
ENCRYPTION=""

while [[ "$#" -gt 1 ]]; do
    curr=$1
    shift
    case $curr in
    -d | --disk)
        DISK="$1"
        shift
        ;;
    -m | --machine)
        MACHINE="$1"
        shift
        ;;
    -e | --encryption)
        ENCRYPTION="$1"
        shift
        ;;
    *)
        echo "Unknown parameter passed: $curr"
        exit 1
        ;;
    esac
done

if [[ ! -e $DISK ]]; then
    echo Disk $DISK is not valid, aborting.
    exit 1
fi

if [[ -z "$MACHINE" ]]; then
    echo Variable MACHINE is not valid, aborting.
    exit 1
fi

if [[ $ENCRYPTION != "plain" && $ENCRYPTION != "password" ]]; then
    echo Unsupported encryption scheme, aborting.
    exit 1
fi

## Now we have the args lined up, start the actual processing

prepare_fake_root

partition_disks $DISK

format_and_mount_boot

case $ENCRYPTION in
plain)
    format_and_mount_nix_plain
    ;;
password)
    format_and_mount_nix_password
    ;;
esac

post_disk_ready

## All done, print notes and quit

echo 'Notes'
echo '1. Generate additional passwords with function: mkpasswd -m sha-512 > [filename]'
echo '2. Initialized configuration.nix, update branch and machine as needed'
