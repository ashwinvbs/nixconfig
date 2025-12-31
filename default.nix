{ config, lib, ... }:

{
  imports = [
    ./components
    (import ./utils/adduser.nix { shortname = "ashwin"; fullname = "Ashwin Balasubramaniyan"; isAdmin = true; })
  ];

  config = lib.mkMerge [
    ({
      # TODO: Figure our how to move this to components.
      # For now keep here as this conflicts with test framework.
      nixpkgs.config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };

      installconfig.impermanence = true;
      users.users.ashwin.openssh.authorizedKeys.keys = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO4lFenwqE4JN51v/7H6wB/QUtiSKbC52rMEjT/zWu5+AAAACHNzaDpja2V5"
      ];
    })

    (lib.mkIf (config.networking.hostName == "nuc") {
      installconfig = {
        always_on = true;
        hardware.intelgpu = true;
      };
    })

    (lib.mkIf (config.networking.hostName == "xps") {
      installconfig = {
        hardware.intelgpu = true;
        workstation_components = true;
      };

      # Add 16G swap to make up for low ram
      swapDevices = [{
        device = "/nix/swapfile";
        size = 1024 * 16;
      }];
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

      # Add 16G swap to make up for low ram
      swapDevices = [{
        device = "/nix/swapfile";
        size = 1024 * 16;
        randomEncryption.enable = true;
      }];

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
