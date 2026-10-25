{
  description = "asyncapi3";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        haskellPackages = pkgs.haskellPackages.override {
          overrides = hself: hsuper: {
            # Dependency overrides go here
          };
        };

        nixpkgsOverlay = _final: _prev: {
          asyncapi3 = self.packages.${system}.asyncapi3;
        };
      in
      rec {
        packages.asyncapi3 = haskellPackages.callCabal2nix "asyncapi3" ./. { };

        defaultPackage = packages.asyncapi3;

        overlays = nixpkgsOverlay;

        devShell = pkgs.mkShell {
          buildInputs = with haskellPackages; [
            haskell-language-server
            ghcid
            cabal-install
          ];
          inputsFrom = [
            self.defaultPackage.${system}.env
          ];
        };
      }
    );
}
