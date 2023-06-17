if [[ ! -e $NIXDISK ]] ; then
    echo Disk $NIXDISK is not valid, aborting.
    exit
fi

sgdisk -Zog $NIXDISK
sgdisk -n 0:0:+1G -t 0:ef00 -c 0:nixboot $NIXDISK
sgdisk -n 0:0:0 -t 0:8300 -c 0:nixsystem $NIXDISK

sleep 10

mkfs.fat -F 32 -n nixboot /dev/disk/by-partlabel/nixboot
mkfs.ext4 -F -L nixsystem /dev/disk/by-partlabel/nixsystem

mount -t tmpfs none /mnt
mkdir -p /mnt/{boot,nix,etc}
mount /dev/disk/by-partlabel/nixboot /mnt/boot
mount /dev/disk/by-partlabel/nixsystem /mnt/nix

mkdir -p /mnt/nix/state/etc/nixos/secrets
# Need this to sidestep impermanence
pushd /mnt/etc/
ln -sf ../nix/state/etc/nixos
popd
# Need this so we can have absolute paths for secrets
pushd /etc/nixos
ln -sf ../../mnt/nix/state/etc/nixos/secrets
popd

nixos-generate-config --root /mnt
cd /mnt/etc/nixos
