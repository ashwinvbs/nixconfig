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
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBovRDhgavqQPYZYMg70tBP3Ibs1o2qSHSAgz4nW89BQwaosDYvmSK0QvT+J8hDVyvIXyaaHMzHONGavMDLVPhUwe1xt6XzrrFNfpZmquLyP9xMRZkxca/c1ZQpD3pL+n7yvY8DMn+6o6B3LPkwYZqbxPlernS1BYQjQbVBMFrkbMzFtacc+GM+fwku2BueOQuNMlrAKdQBTuDLaMlUQyws0CI9PgbB2NSzsmWWohz/r2nWYZmtVAYAjjdRDuoWgL+sUrCQiiDawctHVNHFfkHK1stY3ywD6FOxnm0tvdX8J0ojdCGZdC/LxdxAfdpbN7VmBM9Gw+uyg/ha6LAXaMFEENTYE6JgaWROJNIULHFq2184lSH0P5MVltcywRSvblZZ1vzVwMFrt5HCrJpRa+ROP/HnSUjzN1BmfJMepEAPQTiXSzRQgo0ymX14Oft95w5m+Q5dV0uhuXtSO6ao66EAXcqgSMChUuqqX7MBIu9xxErezfRgesTJOgvRJrtvUk="
      ];
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
