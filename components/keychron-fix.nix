{ config, pkgs, ... }:

{
  environment.etc."modprobe.d/keychron.conf".text = "options hid_apple fnmode=0";
}
