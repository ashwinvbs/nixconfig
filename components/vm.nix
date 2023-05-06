{ config, pkgs, ... }:

let
  impermanence = builtins.fetchTarball {
    url =
      "https://github.com/nix-community/impermanence/archive/master.tar.gz";
  };
in
{
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager ];

  users.users.ashwin.extraGroups = [ "libvirtd" ];

  imports = [ "${impermanence}/nixos.nix" ];
  environment.persistence."/state" = {
    directories = [
      "/var/lib/libvirt"
    ];
  };
}
