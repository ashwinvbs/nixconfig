{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware/intel.nix
    ./components/workstation.nix
  ];
  networking.hostName = "xps";

  users.users.radhulya = {
    isNormalUser = true;
    description = "Radhulya Thirumalaisamy";
    hashedPassword = lib.strings.fileContents /etc/nixos/secrets/radpass.txt;
  };
}
