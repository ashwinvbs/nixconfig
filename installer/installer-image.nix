# Build with following command
# nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=installer-image.nix
{ config, lib, pkgs, ... }:
let
  custom-install-script = pkgs.writeShellScriptBin "nixdisk-setup" ''
    #!/usr/bin/env bash

    if [[ ! -e $NIXDISK ]] ; then
        echo Disk $NIXDISK is not valid, aborting.
        exit
    fi

    if [[ -z "$NIXMACHINE" ]] ; then
        echo Variable NIXMACHINE is not valid, aborting.
        exit
    fi

    sgdisk -Zog $NIXDISK
    sgdisk -n 0:0:+1G -t 0:ef00 -c 0:nixboot $NIXDISK
    sgdisk -n 0:0:0 -t 0:8300 -c 0:nixsystem $NIXDISK

    sleep 10

    mkfs.fat -F 32 -n nixboot /dev/disk/by-partlabel/nixboot

    cryptsetup luksFormat /dev/disk/by-partlabel/nixsystem
    cryptsetup luksOpen /dev/disk/by-partlabel/nixsystem nixsystem
    mkfs.ext4 -F -L nixsystem /dev/mapper/nixsystem

    mount -t tmpfs none /mnt
    mkdir -p /mnt/{boot,nix,etc}

    mount /dev/disk/by-partlabel/nixboot /mnt/boot
    mount /dev/mapper/nixsystem /mnt/nix

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
    mkpasswd -m sha-512 > /mnt/etc/nixos/secrets/ashpass.txt

    nixos-generate-config --root /mnt

    cat >/mnt/etc/nixos/configuration.nix <<EOL
    { ... }:
    {
      imports =
        [
          ./hardware-configuration.nix
          "\''${builtins.fetchGit { url = "https://gitlab.com/ashwin.vbs-workspace/nixconfig.git"; ref = "main"; }}/$NIXMACHINE.nix"
        ];
    }
    EOL

    cd /mnt/etc/nixos

    echo 'Notes'
    echo '1. Generate additional passwords with function: mkpasswd -m sha-512 > [filename]'
    echo '2. Initialized configuration.nix, update branch and machine as needed'

    bash
  '';
in {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix>

    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = lib.mkForce "no";
    };
  };

  # Allow ssh login for user nixos
  users.users.nixos.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBovRDhgavqQPYZYMg70tBP3Ibs1o2qSHSAgz4nW89BQwaosDYvmSK0QvT+J8hDVyvIXyaaHMzHONGavMDLVPhUwe1xt6XzrrFNfpZmquLyP9xMRZkxca/c1ZQpD3pL+n7yvY8DMn+6o6B3LPkwYZqbxPlernS1BYQjQbVBMFrkbMzFtacc+GM+fwku2BueOQuNMlrAKdQBTuDLaMlUQyws0CI9PgbB2NSzsmWWohz/r2nWYZmtVAYAjjdRDuoWgL+sUrCQiiDawctHVNHFfkHK1stY3ywD6FOxnm0tvdX8J0ojdCGZdC/LxdxAfdpbN7VmBM9Gw+uyg/ha6LAXaMFEENTYE6JgaWROJNIULHFq2184lSH0P5MVltcywRSvblZZ1vzVwMFrt5HCrJpRa+ROP/HnSUjzN1BmfJMepEAPQTiXSzRQgo0ymX14Oft95w5m+Q5dV0uhuXtSO6ao66EAXcqgSMChUuqqX7MBIu9xxErezfRgesTJOgvRJrtvUk= ashwin@nuc"
  ];

  environment.systemPackages = [
    custom-install-script
  ];
}