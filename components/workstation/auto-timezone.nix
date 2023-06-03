{ pkgs, ... }:

{
  systemd.services.tzupdate = {
    description = "attempts updating timezone, fails if network is unavailable";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.tzupdate}/bin/tzupdate -z /etc/zoneinfo -d /dev/null";
    };
  };
  systemd.timers.tzupdate = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "10m";
      Unit = "tzupdate.service";
    };
  };
}
