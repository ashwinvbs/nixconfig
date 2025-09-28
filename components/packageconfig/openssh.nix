{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.services.openssh.enable (lib.mkMerge [
    ({
      services.openssh.settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    })

    (lib.mkIf config.installconfig.impermanence {
      environment.persistence."/nix/state".files = [
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
      ];
    })
  ]);
}
