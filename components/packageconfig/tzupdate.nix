{ config, lib, pkgs, ... }:

{
  config.systemd.timers.tzupdate = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "10m";
      Unit = "tzupdate.service";
    };
  };
}
