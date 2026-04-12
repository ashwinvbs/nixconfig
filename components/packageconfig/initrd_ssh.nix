{
  config,
  lib,
  ...
}:

{
  config = lib.mkMerge [
    (lib.mkIf (config.boot.initrd.network.ssh.enable) {
      boot.initrd.network = {
        enable = true;

        # Use the following commands to generate the keys. This is mandatory
        # ssh-keygen -t rsa -N "" -f /etc/nixos/secrets/initrd/ssh_host_rsa_key
        # ssh-keygen -t ed25519 -N "" -f /etc/nixos/secrets/initrd/ssh_host_ed25519_key
        ssh.hostKeys = [
          "/etc/nixos/secrets/initrd/ssh_host_rsa_key"
          "/etc/nixos/secrets/initrd/ssh_host_ed25519_key"
        ];
      };
    })
  ];
}
