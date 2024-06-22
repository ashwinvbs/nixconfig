{ config, lib, ... }:

{
  imports = [
    ./base.nix

    ./components/gaming.nix
    ./components/workstation.nix

    ./hardware.nix
    ./impermanence.nix
    ./users.nix
  ];

  config = lib.mkMerge [
    ( lib.mkIf ( config.networking.hostName == "nuc" ) {
      installconfig.hardware.intel = true;
    } )

    ( lib.mkIf ( config.networking.hostName == "xps" ) {
      installconfig = {
        hardware.intel = true;
        components.workstation = true;
        users.allow-rad = true;
      };
    } )

    ( lib.mkIf ( config.networking.hostName == "rig" ) {
      installconfig = {
        hardware = {
          intel = true;
          amdgpu = true;
        };
        components.workstation = true;
      };
    } )

    ( lib.mkIf ( config.networking.hostName == "fw" ) {
      installconfig = {
        hardware.intel = true;
        components.workstation = true;
      };

      # From https://github.com/NixOS/nixos-hardware/blob/master/framework/12th-gen-intel/default.nix
      boot.kernelParams = [
        "mem_sleep_default=deep"
        "nvme.noacpi=1"
        "i915.enable_psr=1"
      ];
      boot.blacklistedKernelModules = [ "hid-sensor-hub" ];
      boot.extraModprobeConfig = ''
        options snd-hda-intel model=dell-headset-multi
      '';
      services.udev.extraRules = ''
        SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
      '';
      hardware.acpilight.enable = true;
    } )
  ];
}
