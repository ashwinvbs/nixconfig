{ config, lib, pkgs, ... }:

{
  config.systemd.timers.tzupdate = lib.mkIf config.services.tzupdate.enable {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "10m";
      Unit = "tzupdate.service";
    };
  };
}
