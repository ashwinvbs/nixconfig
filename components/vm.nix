{ config, pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager ];

  users.users.ashwin.extraGroups = [ "libvirtd" ];

  imports = [ "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix" ];
  environment.persistence."/nix/state" = {
    directories = [
      "/var/lib/libvirt"
    ];
  };
}
