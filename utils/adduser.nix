{ shortname
, fullname ? shortname
, passprefix ? shortname
, isAdmin ? false
, persist ? {
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
  }
}:
{ config, lib, pkgs, ... }:
{
  config = lib.mkMerge [
    ({
      users.users."${shortname}" = {
        isNormalUser = true;
        description = fullname;
        hashedPassword =
          if builtins.pathExists "/etc/nixos/secrets/${passprefix}_pass.txt" then
            lib.strings.fileContents "/etc/nixos/secrets/${passprefix}_pass.txt"
          else
            null;
      };

      environment.persistence."/nix/state" = {
        users."${shortname}" = persist;
      };
    })

    (lib.mkIf isAdmin {
      users.users."${shortname}".extraGroups = [
        "dialout"
        "wheel"
      ];
      users.groups.adbusers.members = [ "${shortname}" ];
    })

    (lib.mkIf (isAdmin && config.virtualisation.docker.enable) {
      users.groups.docker.members = [ "${shortname}" ];
    })

    (lib.mkIf (isAdmin && config.virtualisation.libvirtd.enable) {
      users.groups.libvirtd.members = [ "${shortname}" ];
    })
  ];
}
