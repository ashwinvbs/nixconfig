{ config, pkgs, ... }:

{
  ## Autoupdate services
  systemd.services.autoupdate_log_boot_info = {
    description = "Auto Update: Log boot generation immediately after bootup";
    wantedBy = [ "multi-user.target" ];
    script = ''
      echo $(date --rfc-3339=seconds): Booting generation $(readlink /nix/var/nix/profiles/system | cut -d- -f2) >> /var/log/autoupdate 
    '';
  };

  systemd.timers.autoupdate_safe = {
    description = "Auto Update: Wait 4 hours to determine the current boot configuraiton to be safe";
    wantedBy = [ "multi-user.target" ];
    timerConfig = {
      OnActiveSec = "4h";
      Unit = "autoupdate_safe.target";
    };
  };
  systemd.targets.autoupdate_safe = {};

  systemd.services.autoupdate_mark_safe = {
    description = "Auto Update: Once current boot is determined to be safe, log that it is safe";
    wantedBy = [ "autoupdate_safe.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      echo $(date --rfc-3339=seconds): Marking current boot as safe >> /var/log/autoupdate 
    '';
  };

  systemd.timers.autoupdate_upgrade = {
    description = "Auto Update: After current boot is determined to be safe, fire upgrade task every 3 hours";
    wantedBy = [ "autoupdate_safe.target" ];
    timerConfig = {
      OnActiveSec = "3h";
      OnUnitActiveSec = "3h";
      Unit = "autoupdate_upgrade.service";
    };
  };
  systemd.services.autoupdate_upgrade = {
    description = "Auto Update: The upgrade task and the corresponding log line";
    wantedBy = [ "autoupdate_safe.target" ];
    serviceConfig.Type = "oneshot";
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    } // config.networking.proxy.envVars;
    path = with pkgs; [
      coreutils
      gnutar
      xz.bin
      gzip
      gitMinimal
      nixos-rebuild
      config.nix.package.out
      config.programs.ssh.package
    ];
    script = ''
      nixos-rebuild boot --upgrade
      echo $(date --rfc-3339=seconds): Attempted upgrade. Current generation is $(readlink /nix/var/nix/profiles/system | cut -d- -f2) >> /var/log/autoupdate 
    '';
  };
}
