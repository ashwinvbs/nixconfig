{ ... }:

{
  imports = [
    ./base.nix
    ./hardware
    ./packageconfig

    "${
      builtins.fetchTarball {
        url =
          "https://github.com/nix-community/impermanence/archive/master.tar.gz";
      }
    }/nixos.nix"
  ];
}
