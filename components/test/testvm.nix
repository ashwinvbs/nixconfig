# If building in isolation, build with the following command
# NIXPKGS_ALLOW_UNFREE=1 nix-build '<nixpkgs/nixos>' -A vm -I nixpkgs=channel:nixos-26.05 -I nixos-config=./testvm.nix
# Ref: https://nix.dev/tutorials/nixos/nixos-configuration-on-vm

{ lib, ... }:

{
  imports = [
    ../default.nix

    (import ../../utils/adduser.nix {
      shortname = "testuser";
      fullname = "Test User";
      isAdmin = true;
      passprefix = "../../blarg";
    })
  ];

  services.displayManager.autoLogin = {
    enable = true;
    user = "testuser";
  };

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
    coder.enable = true;
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
}
