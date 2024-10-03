{ config, lib, pkgs, ... }:

{
  config = lib.mkMerge [
    ( {
      # gnupg and pinentry required for yadm
      environment.systemPackages = with pkgs; [
        pinentry
        yadm
      ];

      users.mutableUsers = false;
    } )

    ( {
      users.users.ashwin = {
        isNormalUser = true;
        description = "Ashwin Balasubramaniyan";
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = config.installconfig.access_keys;
      };
    } )

    ( lib.mkIf config.virtualisation.libvirtd.enable {
      users.users.ashwin.extraGroups = [ "libvirtd" ];
    } )

    ( lib.mkIf config.virtualisation.docker.enable {
      users.users.ashwin.extraGroups = [ "docker" ];
    } )

    ( lib.mkIf config.installconfig.workstation_components {
      users.users.ashwin.extraGroups = [ "adbusers" ];
    } )

    ( lib.mkIf config.installconfig.users.allow_rad {
      users.users.radhulya = {
        isNormalUser = true;
        description = "Radhulya Thirumalaisamy";
      };
    } )

    ( lib.mkIf config.installconfig.enable_impermanence {
      environment.persistence."/nix/state" = {
        users.ashwin = {
          directories = [
            ".android"
            ".config"
            ".local"
            "Documents"
            "Downloads"
            "Music"
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
    } )

    ( lib.mkIf ( config.installconfig.users.allow_rad &&
                 config.installconfig.enable_impermanence ) {
      environment.persistence."/nix/state" = {
        users.radhulya = {
          directories = [
            ".config"
            ".local"
            ".mozilla"
            ".var/app"
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
    } )

    ( lib.mkIf ( config.services.flatpak.enable &&
                 config.installconfig.enable_impermanence ) {
      environment.persistence."/nix/state" = {
        users.ashwin.directories = [ ".var/app" ];
      };
    } )

    ( lib.mkIf ( config.programs.firefox.enable &&
                 config.installconfig.enable_impermanence ) {
      environment.persistence."/nix/state" = {
        users.ashwin.directories = [ ".mozilla" ];
      };
    } )

    ( lib.mkIf ( ! config.installconfig.enable_full_codecoverage_for_test ) {
      users.users.ashwin.hashedPassword = lib.strings.fileContents /etc/nixos/secrets/ashpass.txt;
    } )

    ( lib.mkIf ( ( ! config.installconfig.enable_full_codecoverage_for_test ) && 
                 config.installconfig.users.allow_rad ) {
      users.users.radhulya.hashedPassword = lib.strings.fileContents /etc/nixos/secrets/radpass.txt;
    } )
  ];
}
