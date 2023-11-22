{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.installconfig.workstation-components.enable {
    # This config is required to enable function keys in Keychron K1 keyboard
    environment.etc."modprobe.d/keychron.conf".text = "options hid_apple fnmode=0";
  };
}
