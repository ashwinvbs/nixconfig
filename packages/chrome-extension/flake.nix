{
  description = "A Nix flake to build the Chrome extension CRX package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "chrome-extension";
          version = "1.0.0";

          src = ./.;

          nativeBuildInputs = [
            pkgs.deno
            pkgs.zip
            pkgs.openssl
          ];

          buildPhase = ''
            export DENO_DIR=$TMPDIR/.deno
            # Execute the Deno build script to generate artifacts
            deno run --allow-run --allow-read --allow-write build.ts
          '';

          installPhase = ''
            mkdir -p $out
            # Copy the distribution artifacts and the generated key
            cp -rv dist/* $out/
            [ -f private_key.pem ] && cp private_key.pem $out/
          '';
        };
      });
}