{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/master.tar.gz";
  };
  # New: Load the module
  impermanence = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  };
in {
  # Import the home-manager module.
  imports = [ "${home-manager}/nixos" ];

  users.mutableUsers = false;
  users.users.ashwin = {
    isNormalUser = true;
    description = "Ashwin Balasubramaniyan";
    initialPassword = (builtins.readFile ../secrets/ashpass.txt);
    extraGroups = [ "wheel" ];
  };

  systemd.services.ashwinrequirements = {
    enable = true;
    description = "Creates the directories required by primary users's persistent files";
    requires = [ "state.mount" ];
    wantedBy = [ "home-manager-ashwin" ];
    serviceConfig = {
      ExecStart = [
        ""
        "mkdir -p /state/home/ashwin"
        "chown 1000:100 /state/home/ashwin"
      ];
      Type = "oneshot";
    };
  };

  home-manager.users.ashwin = { pkgs, ... }: {
    # New: Import a persistence module for home-manager.
    imports = [ "${impermanence}/home-manager.nix" ];

    programs.home-manager.enable = true;

    # New: Now we can use the "home.persistence" module, here's an example:
    home.persistence."/state/home/ashwin" = {
      directories = [
        ".config"
        ".gnome/apps"
        ".local/share/applications"
        ".local/share/desktop-directories"
        ".local/share/icons"
        ".local/share/keyrings"
        ".mozilla"
        ".ssh"
        ".vscode"
        "Desktop"
        "Documents"
        "Downloads"
        "Workspace"
      ];
      files = [
        ".bash_aliases"
        ".bash_history"
        ".gitconfig"
      ];
    };
  };
}
