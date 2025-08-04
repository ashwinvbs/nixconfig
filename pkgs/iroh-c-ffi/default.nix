{ pkgs ? import <nixpkgs> { } }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "iroh-c-ffi";
  version = "0.90.0";
  src = pkgs.fetchFromGitHub {
    owner = "n0-computer";
    repo = "${pname}";
    rev = "v${version}";
    sha256 = "sha256-2tTWfyHJqYQbjkjU5g5wEf1JpNoYxc3J6kQTv2HURwg=";
  };

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  postInstall = ''
    mkdir -p $out/include $out/lib
    cp irohnet.h $out/include
    '';
}
