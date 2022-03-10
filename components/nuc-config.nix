{ config, pkgs, ... }:

{
  networking.hostName = "nuc";

  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  users.users.ashwin.initialPassword = (builtins.readFile ../secrets/ashpass.txt);
}
