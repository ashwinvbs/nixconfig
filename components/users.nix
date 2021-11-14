{ config, pkgs, ... }:

{
  users.users.ashwin = {
    isNormalUser = true;
    description = "Ashwin Balasubramaniyan";
    password = "password"; # Change this ASAP!
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };
}

