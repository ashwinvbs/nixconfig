{ config, pkgs, ... }:

{
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  systemd.services.sshdrequirements = {
    enable = true;
    description = "Creates the directories required by ssh persistent files";
    requires = [ "state.mount" ];
    wantedBy = [ "sshd" ];
    serviceConfig = {
      ExecStart = [
        ""
        "mkdir -p /state/sshd/etc/ssh"
      ];
      Type = "oneshot";
    };
  };

  environment.etc."ssh/ssh_host_rsa_key".source         = "/state/sshd/etc/ssh/ssh_host_rsa_key";
  environment.etc."ssh/ssh_host_rsa_key.pub".source     = "/state/sshd/etc/ssh/ssh_host_rsa_key.pub";
  environment.etc."ssh/ssh_host_ed25519_key".source     = "/state/sshd/etc/ssh/ssh_host_ed25519_key";
  environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/state/sshd/etc/ssh/ssh_host_ed25519_key.pub";
}
