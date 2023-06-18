if [[ ! -e $NIXDISK ]] ; then
    echo Disk $NIXDISK is not valid, aborting.
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
      "\${builtins.fetchGit { url = "https://gitlab.com/ashwin.vbs-workspace/nixconfig.git"; ref = "branch"; }}/machine.nix"
    ];
}
EOL

cd /mnt/etc/nixos

echo 'Notes'
echo '1. Generate additional passwords with function: mkpasswd -m sha-512 > [filename]'
echo '2. Initialized configuration.nix, update branch and machine as needed'

bash
