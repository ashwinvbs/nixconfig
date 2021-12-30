{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry
    yadm
  ];
  programs.gnupg.agent.enable = true;

  users.mutableUsers = false;
  users.users.ashwin = {
    isNormalUser = true;
    description = "Ashwin Balasubramaniyan";
    initialPassword = (builtins.readFile ../secrets/ashpass.txt);
    extraGroups = [ "wheel" ];
  };
}
