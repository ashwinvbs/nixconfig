{
  config,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    (lib.mkIf (config.boot.initrd.network.ssh.enable) {
      # This is a hack. When ssh in initrd is enabled, we force disable networkmanager.
      # This makes wifi configuration hard, but it kinda works because any machine
      # that is sshable into boot is meant to be wired in.
      networking.networkmanager.enable = lib.mkForce false;
      boot.initrd = {
        network.ssh.hostKeys = [
          "/etc/nixos/secrets/initrd/ssh_host_rsa_key"
          "/etc/nixos/secrets/initrd/ssh_host_ed25519_key"
        ];
        systemd.network.enable = true;
      };
    })
  ];
}
