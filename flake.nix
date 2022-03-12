{
  description = "A greeting implemented in Haskell + a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, ... }:
    let
      package = { haskellPackages, stdenvNoCC }:
        stdenvNoCC.mkDerivation {
          name = "hello-haskell-flake";

          src = ./.;
          buildInputs = [
            (haskellPackages.ghcWithPackages
              (ps: with ps; [ ]))
          ];

          buildPhase = "ghc -Wall app/Main.hs";
          installPhase = "install -D app/Main $out/bin/hello-haskell-flake";
        };

      module = { pkgs, config, lib, ... }:
        {
          # nixpkgs.overlays = [ self.overlay ];
          environment.systemPackages = [ pkgs.hello-haskell-flake ];
          #systemd.services = { ... };
        };

    in {
      nixosModules.hello-haskell-flake = module;
    } // (utils.lib.eachSystem [ "aarch64-linux" "i686-linux" "x86_64-linux" ]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          hello-haskell-flake = pkgs.callPackage package { };
        in {
          packages.hello-haskell-flake = hello-haskell-flake;
          defaultPackage = hello-haskell-flake;
        }));
}
