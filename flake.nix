{
  description = "A greeting that uses Haskell and flakes.";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        haskellPackages = pkgs.haskellPackages;
        packageName = "hello-haskell-flake";
      in
        {
          packages.${packageName} =
            with haskellPackages; with pkgs;
              mkDerivation {
                pname = packageName;
                version = "0.1.0.0";
                src = ./.;
                isLibrary = false;
                isExecutable = true;
                buildDepends = [ makeWrapper ];
                executableHaskellDepends = [ base directory process random ];
                license = "unknown";
                hydraPlatforms = lib.platforms.none;
              };

          # # A Nixpkgs overlay.
          # overlay = final: prev: {
          #   hello = with final; stdenv.mkDerivation rec {
          #     name = "hello-${version}";
          #     src = ./.;
          #     nativeBuildInputs = [ autoreconfHook ];
          #   };
          # };

          defaultPackage = self.packages.${system}.${packageName};

          # A NixOS module, if applicable (e.g. if the package provides a system service).
          nixosModules.${packageName} =
            { pkgs, ... }:
            {
              nixpkgs.overlays = [ self.overlay ];

              environment.systemPackages = [ packages.${packageName} ];

              #systemd.services = { ... };
            };
        
          devShell = pkgs.mkShell {
            buildInputs = with haskellPackages;
              [ ghc
                haskell-language-server
                cabal-install
              ];
            inputsFrom = builtins.attrValues self.packages.${system};
          };
        }
    );
}
