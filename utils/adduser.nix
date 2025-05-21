{ shortname, fullname }:
{ config, lib, pkgs, ... }:
let
  homePermanence = {
    directories = [
      ".android"
      ".config"
      ".local"
      ".mozilla"
      ".rustup"
      ".var/app"
      ".vscode-oss"
      "Documents"
      "Downloads"
      "Music"
      "Workspaces"
      {
        directory = ".ssh";
        mode = "0700";
      }
    ];
    files = [ ".bash_history" ".bashrc" ".gitconfig" ];
  };
in
{
  config = {
    users.users."${shortname}" = {
      isNormalUser = true;
      description = fullname;
      hashedPassword =
        if builtins.pathExists "/etc/nixos/secrets/${shortname}_pass.txt" then
          lib.strings.fileContents "/etc/nixos/secrets/${shortname}_pass.txt"
        else
          null;
    };

    environment.persistence."/nix/state" = {
      users."${shortname}" = homePermanence;
    };
  };
}