{ config, pkgs, ... }:

{
  networking.hostName = "rig2";

  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp7s0.useDHCP = true;
}
