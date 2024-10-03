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

    access_keys = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDBovRDhgavqQPYZYMg70tBP3Ibs1o2qSHSAgz4nW89BQwaosDYvmSK0QvT+J8hDVyvIXyaaHMzHONGavMDLVPhUwe1xt6XzrrFNfpZmquLyP9xMRZkxca/c1ZQpD3pL+n7yvY8DMn+6o6B3LPkwYZqbxPlernS1BYQjQbVBMFrkbMzFtacc+GM+fwku2BueOQuNMlrAKdQBTuDLaMlUQyws0CI9PgbB2NSzsmWWohz/r2nWYZmtVAYAjjdRDuoWgL+sUrCQiiDawctHVNHFfkHK1stY3ywD6FOxnm0tvdX8J0ojdCGZdC/LxdxAfdpbN7VmBM9Gw+uyg/ha6LAXaMFEENTYE6JgaWROJNIULHFq2184lSH0P5MVltcywRSvblZZ1vzVwMFrt5HCrJpRa+ROP/HnSUjzN1BmfJMepEAPQTiXSzRQgo0ymX14Oft95w5m+Q5dV0uhuXtSO6ao66EAXcqgSMChUuqqX7MBIu9xxErezfRgesTJOgvRJrtvUk=" ];
      description = "Default ssh access keys";
    };

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