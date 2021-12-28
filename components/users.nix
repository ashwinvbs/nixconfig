{ config, pkgs, ... }:

{
  users.mutableUsers = false;
  users.users.ashwin = {
    isNormalUser = true;
    description = "Ashwin Balasubramaniyan";
    initialPassword = (builtins.readFile ../secrets/ashpass.txt);
    extraGroups = [ "wheel" ];
  };
}
