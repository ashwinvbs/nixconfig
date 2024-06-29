# To execute test, use the following command: nix-build ./test.nix
# Ref: https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html

let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs {
    config.allowUnfree = true;
    overlays = [];
  };
in

pkgs.testers.runNixOSTest {
  name = "Integration Test";
  nodes.machine = import ./sanity.nix;
  testScript = { nodes, ... }: ''
    machine.wait_for_unit("default.target")
    machine.succeed("su -- ashwin -c 'which chromium'")
  '';
}