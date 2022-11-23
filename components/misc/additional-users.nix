{ config, pkgs, ... }:

{
  users.users.radhulya = {
    isNormalUser = true;
    description = "Radhulya Thirumalaisamy";
    hashedPassword = lib.strings.fileContents /etc/nixos/secrets/radpass.txt;
  };
}
