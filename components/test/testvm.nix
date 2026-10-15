# If building in isolation, build with the following command
# nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-26.05 -I nixos-config=./testvm.nix
# Ref: https://nix.dev/tutorials/nixos/nixos-configuration-on-vm

{ ... }:

{
  imports = [ ../default.nix ];
  networking.hostName = "testing";

  installconfig = {
    impermanence = {
      enable = true;
      retainLogs = true;
    };
    devtools = true;
    godotdev = true;
    hardware = {
      intelgpu = true;
      amdgpu = true;
    };
    workstationComponents = true;
    enableVirtualCamera = true;
    enableAudioSink = true;
  };

  programs.firefox.enable = true;

  hardware = {
    sane.enable = true;
  };

  services = {
    fprintd.enable = true;
    ollama.enable = true;
    printing.enable = true;
    tailscale.enable = true;
    tailscale.provisionCert.enable = true;
    nginx.enable = true;
  };

  virtualisation = {
    # Required to test impermanence
    # Yes, persistent storage is also on tmpfs,
    # but this config does exercise all paths of impermanence
    # - persistent path creation and mounting onto tmpfs root.
    diskImage = null;

    docker.enable = true;
    libvirtd.enable = true;
    waydroid.enable = true;
  };

  users.users.testuser = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "testpass";
  };
}
