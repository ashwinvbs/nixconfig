{ config, lib, pkgs, ... }:

{
  config.system.autoUpgrade = lib.mkIf config.system.autoUpgrade.enable (lib.mkMerge [
    ({
      randomizedDelaySec = "30min";
      flags = [
        "--option"
        "tarball-ttl"
        "0"
      ];
      dates = "daily";
    })

    (lib.mkIf config.installconfig.workstation_components {
      operation = "boot";
    })

    (lib.mkIf (!config.installconfig.workstation_components) {
      allowReboot = true;
      rebootWindow = {
        lower = "01:00";
        upper = "03:00";
      };
    })
  ]);
}
