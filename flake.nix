{
  description = "My haskell application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        haskellPackages = pkgs.haskellPackages;

        jailbreakUnbreak = pkg:
          pkgs.haskell.lib.doJailbreak (pkg.overrideAttrs (_: { meta = { }; }));

        packageName = "hello-haskell-flake";
        versionNum = "0.1.0.0";
      in {
        packages.${packageName} = pkgs.stdenv.mkDerivation rec {
          pname = "${packageName}";
          version = "${versionNum}";

          src = ./.;

          nativeBuildInputs = [
            pkgs.cabal-install
            pkgs.ghc
          ];

          unpackPhase =
            ''
              cp -r $src/* .
            '';

          configurePhase =
            ''
              mkdir -p cabal
              CABAL_DIR=$PWD/cabal cabal user-config init
              sed --in-place '/^repository /d; /^ *url:/d; /^ *--/d' cabal/config
            '';

          buildPhase =
            ''
              CABAL_DIR=$PWD/cabal cabal build
            '';

          installPhase =
            ''
              CABAL_DIR=$PWD/cabal cabal install
              mkdir -p $out/bin
              cp cabal/bin/${packageName} $out/bin/
            '';
        };

        defaultPackage = self.packages.${system}.${packageName};

        # This stuff will be available when you run nix develop, but not nix build.
        devShell = pkgs.mkShell {
          buildInputs = with haskellPackages; [
            haskell-language-server
            ghcid
            cabal-install
          ];
          inputsFrom = builtins.attrValues self.packages.${system};
        };

        # A NixOS module, if applicable (e.g. if the package provides a system service).
        nixosModules.${packageName}  =
          { pkgs, ... }:
          {
            nixpkgs.overlays = [ self.overlay ];
            environment.systemPackages = [ pkgs.${packageName}  ];
            #systemd.services = { ... };
          };
      });
}

