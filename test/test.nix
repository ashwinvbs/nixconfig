# Ref: https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html#what-do-you-need

let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs {
    config = {
      # There has to be a better way.
      # For now, copying from workstation.nix
      allowUnfree = true;
      chromium = {
        enableWideVine = true;
        # From https://chromium.googlesource.com/chromium/src/+/master/docs/gpu/vaapi.md
        commandLineArgs = "--use-gl=angle --use-angle=gl --enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiOnNvidiaGPUs --ignore-gpu-blocklist --disable-gpu-driver-bug-workaround";
      };
    };
    overlays = [];
  };
in

pkgs.testers.runNixOSTest {
  name = "Sanity Test";
  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../config.nix
    ];

    networking.hostName = "test";

    system.stateVersion = "24.05";
  };
  testScript = { nodes, ... }: ''
    machine.wait_for_unit("default.target")
    machine.succeed("su -- ashwin -c 'which chromium'")
  '';
}