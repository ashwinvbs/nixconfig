{ config, lib, ... }:

{
  imports = [ ./components ];

  config = lib.mkMerge [
    ({
      # TODO: Figure our how to move this to components.
      # For now keep here as this conflicts with test framework.
      nixpkgs.config.allowUnfree = true;
    })

    (lib.mkIf (config.networking.hostName == "nuc") {
      installconfig = {
        hardware.intelgpu = true;
      };
    })

    (lib.mkIf (config.networking.hostName == "xps") {
      installconfig = {
        hardware.intelgpu = true;
        workstation_components = true;
      };
    })

    (lib.mkIf (config.networking.hostName == "rig") {
      installconfig = {
        hardware.amdgpu = true;
        workstation_components = true;
      };
    })

    (lib.mkIf (config.networking.hostName == "fw") {
      installconfig = {
        hardware.intelgpu = true;
        workstation_components = true;
      };

      # From https://github.com/NixOS/nixos-hardware/blob/master/framework/12th-gen-intel/default.nix
      boot.kernelParams =
        [ "mem_sleep_default=deep" "nvme.noacpi=1" "i915.enable_psr=1" ];
      boot.blacklistedKernelModules = [ "hid-sensor-hub" ];
      boot.extraModprobeConfig = ''
        options snd-hda-intel model=dell-headset-multi
      '';
      services.udev.extraRules = ''
        SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
      '';
      hardware.acpilight.enable = true;
    })

    (lib.mkIf (config.networking.hostName == "rpi4") {
      installconfig.hardware.rpi4 = true;
    })
  ];
}
