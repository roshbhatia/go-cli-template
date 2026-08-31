{
  description = "Nix-first Go CLI template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      formatter = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellApplication {
          name = "go-cli-template-format";
          runtimeInputs = [
            pkgs.fd
            pkgs.nixfmt
          ];
          text = ''
            if [ "$#" -gt 0 ] && [ "''${1#-}" = "$1" ]; then
              exec nixfmt "$@"
            fi
            exec fd --extension nix --type file --exec-batch nixfmt "$@"
          '';
        }
      );

      packages = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          example = pkgs.buildGoModule {
            pname = "example";
            version = "0.1.0";
            src = ./.;
            vendorHash = "sha256-OuLseKw0Z8ZpJHjZrkyHMb5O4VYXCDWL2NykdeKjQXY=";
            subPackages = [ "cmd/example" ];
            ldflags = [ "-s -w -X main.version=0.1.0" ];
            meta = {
              description = "Example composable Go CLI";
              homepage = "https://github.com/roshbhatia/go-cli-template";
              license = pkgs.lib.licenses.mit;
              mainProgram = "example";
              platforms = pkgs.lib.platforms.unix;
            };
          };
        in
        {
          inherit example;
          default = example;
        }
      );

      apps = eachSystem (system: {
        default = {
          type = "app";
          program = "${nixpkgs.lib.getExe self.packages.${system}.default}";
        };
      });

      checks = eachSystem (system: {
        default = self.packages.${system}.default;
      });

      devShells = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.go
              pkgs.gopls
              pkgs.gotools
              pkgs.go-tools
              pkgs.goreleaser
              pkgs.ripgrep
            ];
            shellHook = ''
              export GOTOOLCHAIN=local
            '';
          };
        }
      );
    };
}
