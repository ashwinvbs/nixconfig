{
  shortname,
  fullname ? shortname,
  passprefix ? shortname,
  isAdmin ? false,
  persist ? {
    directories = [
      ".android"
      ".antigravity"
      ".config"
      ".gemini"
      ".local"
      ".rustup"
      ".var/app"
      "Documents"
      "Downloads"
      "Music"
      "Projects"
      "Workspaces"
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

      environment.persistence."/nix/state" = {
        users."${shortname}" = persist;
      };
    })

    (lib.mkIf isAdmin {
      users.users."${shortname}".extraGroups =
        [
          "dialout"
          "wheel"
        ]
        ++ lib.optional config.hardware.sane.enable "scanner"
        ++ lib.optional config.services.printing.enable "lp"
        ++ lib.optional config.virtualisation.libvirtd.enable "libvirtd";
    })
  ];
}
