if [[ ! -e $NIXDISK ]] ; then
    echo Disk $NIXDISK is not valid, aborting.
    exit
fi

if [[ ! -e $USBDISK ]] ; then
    echo Disk $USBDISK is not valid, aborting.
    exit
fi

sgdisk -Zog $NIXDISK
sgdisk -n 0:0:0 -t 0:8300 -c 0:nixcrypted $NIXDISK

sgdisk -Zog $USBDISK
sgdisk -n 0:0:+256M -t 0:ef00 -c 0:nixboot $USBDISK
sgdisk -n 0:0:+32M -t 0:8300 -c 0:nixconfig $USBDISK
sgdisk -n 0:0:+8M -t 0:8300 -c 0:nixkey $USBDISK
sgdisk -n 0:0:+8M -t 0:8300 -c 0:nixheader $USBDISK
sgdisk -n 0:0:0 -t 0:8300 -c 0:nixusbdata $USBDISK

dd bs=512 count=16 if=/dev/random of=/dev/disk/by-partlabel/nixkey iflag=fullblock
cryptsetup luksFormat /dev/disk/by-partlabel/nixcrypted \
    --type luks2 \
    --header $(readlink -f /dev/disk/by-partlabel/nixheader) \
    --key-file /dev/disk/by-partlabel/nixkey \
    --key-size 512
cryptsetup luksOpen /dev/disk/by-partlabel/nixcrypted crypted \
    --header $(readlink -f /dev/disk/by-partlabel/nixheader) \
    --key-file /dev/disk/by-partlabel/nixkey \
    --key-size 512

pvcreate /dev/mapper/crypted
vgcreate vg /dev/mapper/crypted

lvcreate -L 24G -n nixsystem vg
lvcreate -l '100%FREE' -n nixdata vg

mkfs.fat -F 32 -n nixboot /dev/disk/by-partlabel/nixboot
mkfs.ext4 -F -L nixconfig /dev/disk/by-partlabel/nixconfig
mkfs.ext4 -F -L nixsystem /dev/vg/nixsystem
mkfs.ext4 -F -L nixdata /dev/vg/nixdata

mount -t tmpfs none /mnt
mkdir -p /mnt/{boot,nix,etc/nixos,state}
mount /dev/disk/by-partlabel/nixboot /mnt/boot
mount /dev/disk/by-partlabel/nixconfig /mnt/etc/nixos
mount /dev/vg/nixsystem /mnt/nix
mount /dev/vg/nixdata /mnt/state

nixos-generate-config --root /mnt
cd /mnt/etc/nixos
