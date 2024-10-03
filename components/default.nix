{ ... }:

{
  imports = [
    ./base.nix
    ./hardware.nix
    ./installconfig.nix
    ./packageconfig.nix
    ./users.nix

    "${builtins.fetchTarball { url = "https://github.com/nix-community/impermanence/archive/master.tar.gz"; }}/nixos.nix"
  ];
}