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
        with lib;
        let
          cfg = config.services.hello-haskell-flake;
          hello-haskell-flake = "${self.packages.${pkgs.system}.hello-haskell-flake}/bin/hello-haskell-flake";
        in {
          options.services.hello-haskell-flake = {
            enable = mkEnableOption "Automatic fan controller";

            location = mkOption {
              description = "Location to fetch temperature data for.";
              type = types.str;
            };
          };

          config.systemd.services.hello-haskell-flake = {
            description = "Automatic fan controller";

            wants = [ "network-online.target" ];
            after = [ "network-online.target" ];
            wantedBy = [ "default.target" ];

            serviceConfig = {
              Restart = "on-failure";
              ExecStart = "${hello-haskell-flake} ${escapeShellArg cfg.location}";
            };

            # The Haskell program assumes that the fan is off when it starts
            preStart = "echo 1-1 >/sys/bus/usb/drivers/usb/unbind || exit 0";
            postStop = "echo 1-1 >/sys/bus/usb/drivers/usb/unbind || exit 0";
          };
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
