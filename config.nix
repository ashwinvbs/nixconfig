{ config, lib, ... }:

{
  imports = [
    ./components/base.nix
    ./components/hardware.nix
    ./components/impermanence.nix
    ./components/users.nix
    ./components/workstation.nix
  ];

  config = lib.mkMerge [
    ( lib.mkIf ( config.networking.hostName == "nuc" ) {
      installconfig = {
        enable_impermanence = true;
        hardware.intel = true;
      };
    } )

    ( lib.mkIf ( config.networking.hostName == "xps" ) {
      installconfig = {
        enable_impermanence = true;
        hardware.intel = true;
        workstation_components = true;
        users.allow-rad = true;
      };
    } )

    ( lib.mkIf ( config.networking.hostName == "rig" ) {
      installconfig = {
        enable_impermanence = true;
        hardware = {
          intel = true;
          amdgpu = true;
        };
        workstation_components = true;
      };
    } )

    ( lib.mkIf ( config.networking.hostName == "fw" ) {
      installconfig = {
        enable_impermanence = true;
        hardware.intel = true;
        workstation_components = true;
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

    ( lib.mkIf ( config.networking.hostName == "enable_all" ) {
      installconfig = {
        enable_impermanence = true;
        hardware = {
          intel = true;
          amdgpu = true;
        };
        users.allow-rad = true;
        workstation_components = true;
      };
      services.fprintd.enable = true;
      virtualisation.docker.enable = true;
    } )
  ];
}
