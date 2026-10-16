{
  shortname,
  fullname ? shortname,
  passprefix ? shortname,
  isAdmin ? false,
  persist ? {
    directories = [
      ".local"
      ".rustup"
      ".var/app"
      ".vscode-oss"
      "Documents"
      "Downloads"
      "Music"
      "Projects"
      {
        directory = ".android";
        mode = "0750";
      }
      {
        directory = ".config";
        mode = "0700";
      }
      {
        directory = ".ssh";
        mode = "0700";
      }
    ];
    files = [
      ".bash_history"
      ".gitconfig"
    ];
  },
}:
{
  config,
  lib,
  pkgs,
  ...
}:
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
    })

    (lib.mkIf config.installconfig.impermanence.enable {
      environment.persistence."/nix/state" = {
        users."${shortname}" = persist;
      };
    })

    (lib.mkIf isAdmin {
      users.users."${shortname}".extraGroups = [
        "dialout"
        "wheel"
      ]
      ++ lib.optional config.hardware.sane.enable "scanner"
      ++ lib.optional config.services.printing.enable "lp"
      ++ lib.optional config.virtualisation.libvirtd.enable "libvirtd";
    })
  ];
}
