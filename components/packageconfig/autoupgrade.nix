{
  config,
  lib,
  ...
}:

{
  config.system.autoUpgrade = lib.mkMerge [
    ({
      randomizedDelaySec = "30min";
      flags = [
        "--option"
        "tarball-ttl"
        "0"
      ];
      dates = "daily";
    })

    (lib.mkIf config.installconfig.workstationComponents {
      operation = "boot";
    })

    (lib.mkIf (!config.installconfig.workstationComponents) {
      allowReboot = true;
      rebootWindow = {
        lower = "01:00";
        upper = "03:00";
      };
    })
  ];
}
