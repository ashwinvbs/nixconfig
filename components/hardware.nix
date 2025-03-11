{ config, lib, pkgs, ... }:

{
  options.installconfig.hardware = {
    intelgpu = lib.mkEnableOption "Enable driver support for intel gpu";
    amdgpu = lib.mkEnableOption "Enable driver support for amdgpu";
    rpi4 = lib.mkEnableOption "Enable driver and boot support for Raspberry pi 4";
  };

  config = lib.mkMerge [
    ({
      services = {
        # Firmware management service
        fwupd.enable = true;

        # SSD management service
        fstrim.enable = true;
      };
    })

    (lib.mkIf pkgs.stdenv.hostPlatform.isEfi {
      # Default boot configuration for UEFI systems
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
    })

    (lib.mkIf config.installconfig.hardware.intelgpu {
      environment.systemPackages = with pkgs; [ intel-gpu-tools ];

      boot.initrd.kernelModules = [ "i915" ];

      environment.variables = { VDPAU_DRIVER = "va_gl"; };

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          vaapiIntel
          libvdpau-va-gl
          intel-media-driver
        ];
      };
    })

    (lib.mkIf config.installconfig.hardware.amdgpu {
      environment.systemPackages = with pkgs; [ radeontop ];

      services.xserver.videoDrivers = lib.mkDefault [ "modesetting" ];
      hardware.amdgpu.initrd.enable = true;

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          rocmPackages.clr.icd
        ];
      };
    })

    (lib.mkIf config.installconfig.hardware.rpi4 {
      boot = {
        kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
        loader.generic-extlinux-compatible.enable = true;
      };
      networking.wireless.enable = true;
    })
  ];
}
