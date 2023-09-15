{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware/intel.nix
    ./components/workstation.nix
    "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix"
  ];
  networking.hostName = "xps";

  users.users.radhulya = {
    isNormalUser = true;
    description = "Radhulya Thirumalaisamy";
    hashedPassword = lib.strings.fileContents /etc/nixos/secrets/radpass.txt;
  };

  environment.persistence."/nix/state" = {
    hideMounts = true;
    users.radhulya = {
      directories = [
        ".config"
        ".local"
        "Documents"
        "Downloads"
        "Workspaces"
      ];
      files = [
        ".bash_history"
        ".bashrc"
        ".gitconfig"
      ];
    };
  };
}
