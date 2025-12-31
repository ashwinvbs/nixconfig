{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.virtualisation.waydroid.enable (lib.mkMerge [
    ({
      systemd.tmpfiles.settings."99-waydroid-settings"."/var/lib/waydroid/waydroid_base.prop".C = {
        user = "root";
        group = "root";
        mode = "0644";
        argument = builtins.toString (pkgs.writeText "waydroid_base.prop" ''
          sys.use_memfd=true
        '');
      };
    })

    (lib.mkIf config.installconfig.impermanence.enable {
      environment.persistence."/nix/state".directories = [ "/var/lib/waydroid" ];
    })
  ]);
}
