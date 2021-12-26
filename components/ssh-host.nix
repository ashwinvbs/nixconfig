{ config, pkgs, ... }:

let
  impermanence = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  };
in {
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  imports = [ "${impermanence}/nixos.nix" ];
  environment.persistence."/state" = {
    files = [
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  environment.etc."ssh/ssh_host_rsa_key".source         = "/state/sshd/etc/ssh/ssh_host_rsa_key";
  environment.etc."ssh/ssh_host_rsa_key.pub".source     = "/state/sshd/etc/ssh/ssh_host_rsa_key.pub";
  environment.etc."ssh/ssh_host_ed25519_key".source     = "/state/sshd/etc/ssh/ssh_host_ed25519_key";
  environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/state/sshd/etc/ssh/ssh_host_ed25519_key.pub";
}
