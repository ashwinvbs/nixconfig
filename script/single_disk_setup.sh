if [[ ! -e $NIXDISK ]] ; then
    echo Disk $NIXDISK is not valid, aborting.
    exit
fi

sgdisk -Zog $NIXDISK
sgdisk -n 0:0:+496M -t 0:ef00 -c 0:nixboot $NIXDISK
sgdisk -n 0:0:+16M -t 0:8300 -c 0:nixconfig $NIXDISK
sgdisk -n 0:0:+24G -t 0:8300 -c 0:nixsystem $NIXDISK
sgdisk -n 0:0:0 -t 0:8300 -c 0:nixdata $NIXDISK

sleep 10

mkfs.fat -F 32 -n nixboot /dev/disk/by-partlabel/nixboot
mkfs.ext4 -F -L nixconfig /dev/disk/by-partlabel/nixconfig
mkfs.ext4 -F -L nixsystem /dev/disk/by-partlabel/nixsystem
mkfs.ext4 -F -L nixdata /dev/disk/by-partlabel/nixdata

mount -t tmpfs none /mnt
mkdir -p /mnt/{boot,nix,etc/nixos,state}
mount /dev/disk/by-partlabel/nixboot /mnt/boot
mount /dev/disk/by-partlabel/nixconfig /mnt/etc/nixos
mount /dev/disk/by-partlabel/nixsystem /mnt/nix
mount /dev/disk/by-partlabel/nixdata /mnt/state

nixos-generate-config --root /mnt
cd /mnt/etc/nixos
