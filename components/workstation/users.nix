{ ... }:

{
  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];
  environment.persistence."/nix/state" = {
    hideMounts = true;
    users.ashwin = {
      directories = [
        ".android"
        ".config"
        ".local"
        "Documents"
        "Downloads"
        "Workspaces"
        { directory = ".ssh"; mode = "0700"; }
      ];
      files = [
        ".bash_history"
        ".bashrc"
        ".gitconfig"
      ];
    };
  };
}
