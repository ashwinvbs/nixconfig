{ config, lib, ... }:

{
  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];

  options.installconfig.users.allow-rad = lib.mkEnableOption "Adds radhulya as a normal user";

  config = lib.mkIf config.installconfig.users.allow-rad {
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
  };
}