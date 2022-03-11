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
                postInstall = ''
                          wrapProgram $out/bin/${packageName} \
                            --prefix PATH : ${lib.getBin pkgs.swaybg}/bin
                              '';
              };

          defaultPackage = self.packages.${system}.${packageName};

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