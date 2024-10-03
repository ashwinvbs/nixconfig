{ config, lib, ... }:

{
  options.installconfig = {
    enable_impermanence = lib.mkEnableOption "Enable impermanence";
    hardware = {
      intel = lib.mkEnableOption "Enable driver support for intel cpu/gpu";
      amdgpu = lib.mkEnableOption "Enable driver support for amdgpu";
    };
    users.allow_rad = lib.mkEnableOption "Adds radhulya as a normal user";
    workstation_components = lib.mkEnableOption "Configure the machine to be a workstation";
    auto_timezone = lib.mkEnableOption "Enable network based setting of timezone";

    # Test only
    enable_full_codecoverage_for_test = lib.mkEnableOption "Enable full code coverage for testing";
  };

  config = lib.mkIf config.installconfig.enable_full_codecoverage_for_test {
    installconfig = {
      auto_timezone = true;
      enable_impermanence = true;
      hardware = {
        intel = true;
        amdgpu = true;
      };
      users.allow_rad = true;
      workstation_components = true;
    };

    services.fprintd.enable = true;
    virtualisation = {
      docker.enable = true;
      libvirtd.enable = true;
    };
  };
}