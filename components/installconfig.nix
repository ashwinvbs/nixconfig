{ config, lib, ... }:

{
  options.installconfig = {
    enable_impermanence = lib.mkEnableOption "Enable impermanence";
    hardware = {
      intel = lib.mkEnableOption "Enable driver support for intel cpu/gpu";
      amdgpu = lib.mkEnableOption "Enable driver support for amdgpu";
    };
    users.allow-rad = lib.mkEnableOption "Adds radhulya as a normal user";
    workstation_components = lib.mkEnableOption "Configure the machine to be a workstation";

    # Test only
    enable_full_codecoverage_for_test = lib.mkEnableOption "Enable full code coverage for testing";
  };

  config = lib.mkIf config.installconfig.enable_full_codecoverage_for_test {
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
    virtualisation = {
      docker.enable = true;
      libvirtd.enable = true;
    };
  };
}