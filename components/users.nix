{ config, lib, pkgs, ... }:

{
  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];

  options.installconfig.users.allow-rad = lib.mkEnableOption "Adds radhulya as a normal user";

  config = lib.mkMerge [
    ( {
      # gnupg and pinentry required for yadm
      environment.systemPackages = with pkgs; [
        gnupg
        pinentry
        yadm
      ];
      programs.gnupg.agent.enable = true;

      users.mutableUsers = false;
    } )

    ( {
      users.users.ashwin = {
        isNormalUser = true;
        description = "Ashwin Balasubramaniyan";
        hashedPassword = lib.strings.fileContents /etc/nixos/secrets/ashpass.txt;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBovRDhgavqQPYZYMg70tBP3Ibs1o2qSHSAgz4nW89BQwaosDYvmSK0QvT+J8hDVyvIXyaaHMzHONGavMDLVPhUwe1xt6XzrrFNfpZmquLyP9xMRZkxca/c1ZQpD3pL+n7yvY8DMn+6o6B3LPkwYZqbxPlernS1BYQjQbVBMFrkbMzFtacc+GM+fwku2BueOQuNMlrAKdQBTuDLaMlUQyws0CI9PgbB2NSzsmWWohz/r2nWYZmtVAYAjjdRDuoWgL+sUrCQiiDawctHVNHFfkHK1stY3ywD6FOxnm0tvdX8J0ojdCGZdC/LxdxAfdpbN7VmBM9Gw+uyg/ha6LAXaMFEENTYE6JgaWROJNIULHFq2184lSH0P5MVltcywRSvblZZ1vzVwMFrt5HCrJpRa+ROP/HnSUjzN1BmfJMepEAPQTiXSzRQgo0ymX14Oft95w5m+Q5dV0uhuXtSO6ao66EAXcqgSMChUuqqX7MBIu9xxErezfRgesTJOgvRJrtvUk= ashwin@nuc"
        ];
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

    ( lib.mkIf config.installconfig.users.allow-rad {
      users.users.radhulya = {
        isNormalUser = true;
        description = "Radhulya Thirumalaisamy";
        hashedPassword = lib.strings.fileContents /etc/nixos/secrets/radpass.txt;
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

    ( lib.mkIf ( config.installconfig.users.allow-rad &&
                 config.installconfig.enable_impermanence ) {
      environment.persistence."/nix/state" = {
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
    } )

    ( lib.mkIf ( config.services.flatpak.enable &&
                 config.installconfig.enable_impermanence ) {
      environment.persistence."/nix/state" = {
        users.ashwin.directories = [ ".var/app" ];
      };
    } )
  ];
}
