{ config, lib, pkgs, ... }:

{
  options.installconfig.always_on = lib.mkEnableOption "Configures a system to be always on";

  config = lib.mkIf config.installconfig.always_on (lib.mkMerge [
    ({
      systemd.sleep.extraConfig = ''
        AllowSuspend=no
        AllowHibernation=no
        AllowHybridSleep=no
        AllowSuspendThenHibernate=no
      '';
    })

    (lib.mkIf config.security.polkit.enable {
      # IDE configuration
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.login1.reboot" ||
                action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
                action.id == "org.freedesktop.login1.reboot-ignore-inhibit" ||
                action.id == "org.freedesktop.login1.power-off" ||
                action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
                action.id == "org.freedesktop.login1.power-off-ignore-inhibit")
            {
                return polkit.Result.NO;
            }
        });
      '';
    })
  ]);
}
