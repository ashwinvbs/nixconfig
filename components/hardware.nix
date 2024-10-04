{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.installconfig = {
    hardware = {
      intel = lib.mkEnableOption "Enable driver support for intel cpu/gpu";
      amdgpu = lib.mkEnableOption "Enable driver support for amdgpu";
    };
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

    (lib.mkIf config.installconfig.hardware.intel {
      # CPU configuration
      hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

      # GPU configuration
      boot.initrd.kernelModules = [ "i915" ];

      environment.variables = {
        VDPAU_DRIVER = "va_gl";
      };

      hardware.opengl = {
        enable = true;
        driSupport = true;
        extraPackages = with pkgs; [
          vaapiIntel
          libvdpau-va-gl
          intel-media-driver
        ];
      };
    })

    (lib.mkIf config.installconfig.hardware.amdgpu {
      environment.systemPackages = with pkgs; [ radeontop ];

      boot.initrd.kernelModules = [ "amdgpu" ];
      services.xserver.videoDrivers = [ "amdgpu" ];

      hardware.opengl = {
        enable = true;
        driSupport = true;
        extraPackages = with pkgs; [
          rocm-opencl-icd
          rocm-opencl-runtime
        ];
      };
    })
  ];
}
