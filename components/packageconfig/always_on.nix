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
        polkit.addRule(function (action, subject) {
          if (
            !subject.isInGroup("wheel") &&
            [
              "org.freedesktop.login1.reboot",
              "org.freedesktop.login1.reboot-multiple-sessions",
              "org.freedesktop.login1.reboot-ignore-inhibit"
              "org.freedesktop.login1.power-off",
              "org.freedesktop.login1.power-off-multiple-sessions",
              "org.freedesktop.login1.power-off-ignore-inhibit",
            ].indexOf(action.id) !== -1
          ) {
            return polkit.Result.NO;
          }
        });
      '';
    })
  ]);
}
