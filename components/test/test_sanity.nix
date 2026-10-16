# To execute test, use the following command: nix-build ./test_sanity.nix
# Ref: https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html

let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-26.05";
  pkgs = import nixpkgs {
    config.allowUnfree = true;
    overlays = [ ];
  };
in
pkgs.testers.runNixOSTest {
  name = "Sanity Test";
  nodes.machine = import ./testvm.nix;
  testScript = ''
    machine.wait_for_unit("default.target")
    machine.succeed("su -- testuser -c 'which google-chrome-stable'")
    machine.succeed("findmnt --noheadings --output FSTYPE --target / | grep -qx tmpfs")
  '';
}
