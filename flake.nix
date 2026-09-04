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
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      eachSystem = nixpkgs.lib.genAttrs supportedSystems;
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
          version = nixpkgs.lib.removeSuffix "\n" (builtins.readFile ./VERSION);
          example = pkgs.buildGoModule {
            pname = "example";
            inherit version;
            src = ./.;
            vendorHash = "sha256-87L0GV7dzz0Y3EsYH8YaTara4aEA5UAC0kfAw+0Ju9g=";
            subPackages = [ "cmd/main" ];
            nativeBuildInputs = [ pkgs.installShellFiles ];
            nativeCheckInputs = [
              pkgs.bash
              pkgs.fish
              pkgs.nushell
              pkgs.zsh
            ];
            checkPhase = ''
              runHook preCheck
              go test -race ./...
              ./hack/generate.sh --check
              bash -n completions/example.bash
              fish --no-config -n completions/example.fish
              nu --no-config-file --no-std-lib -c 'source completions/example.nu'
              zsh -n completions/_example
              runHook postCheck
            '';
            ldflags = [ "-s -w -X main.version=${version}" ];
            postInstall = ''
              mv "$out/bin/main" "$out/bin/example"
              installShellCompletion --cmd example \
                --bash completions/example.bash \
                --fish completions/example.fish \
                --zsh completions/_example
              mkdir -p "$out/share/nushell/vendor/autoload"
              install -m 0444 completions/example.nu "$out/share/nushell/vendor/autoload/example.nu"
            '';
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

      checks = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          fakeGo = pkgs.writeShellScriptBin "go" "exit 0";
        in
        {
          default = self.packages.${system}.default;
          repository =
            pkgs.runCommand "go-cli-template-repository-check"
              {
                nativeBuildInputs = [
                  pkgs.actionlint
                  pkgs.bash
                  pkgs.gitMinimal
                  pkgs.perl
                  pkgs.shellcheck
                  pkgs.shfmt
                ];
              }
              ''
                actionlint ${./.github/workflows/ci.yml} ${./.github/workflows/release.yml}
                shellcheck ${./hack/generate.sh} ${./hack/init-template.sh} ${./hack/verify-release-tag.sh}
                shfmt -i 2 -ci -sr -s -d ${./hack/generate.sh} ${./hack/init-template.sh} ${./hack/verify-release-tag.sh}

                if grep -q '"initialized": false' ${./template.json}; then
                  if bash ${./hack/init-template.sh} valid-owner valid-project invalid.binary; then
                    echo "initializer accepted an invalid Nix binary name" >&2
                    exit 1
                  fi
                  for invalid_owner in owner- -owner owner--name aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa; do
                    if bash ${./hack/init-template.sh} "$invalid_owner" valid-project valid-binary; then
                      echo "initializer accepted invalid GitHub owner $invalid_owner" >&2
                      exit 1
                    fi
                  done

                  collision_project="exam""ple-tools"
                  fixture="$TMPDIR/$collision_project"
                  cp -R ${./.}/. "$fixture"
                  chmod -R u+w "$fixture"
                  (
                    cd "$fixture"
                    git init --quiet
                    git add .
                    PATH="${fakeGo}/bin:$PATH" bash ./hack/init-template.sh acme-labs "$collision_project" greet
                    grep -qx "module github.com/acme-labs/$collision_project" go.mod
                    grep -q 'owner: acme-labs' .goreleaser.yaml
                    grep -q "\"project\": \"$collision_project\"" template.json
                    grep -q '"binary": "greet"' template.json
                    grep -q '"initialized": true' template.json
                    bad_collision="greet""-tools"
                    ! grep -R -q "$bad_collision" README.md go.mod template.json .github .goreleaser.yaml
                  )

                  identity_fixture="$TMPDIR/identity"
                  cp -R ${./.}/. "$identity_fixture"
                  chmod -R u+w "$identity_fixture"
                  (
                    cd "$identity_fixture"
                    git init --quiet
                    git add .
                    PATH="${fakeGo}/bin:$PATH" bash ./hack/init-template.sh acme-labs sample example
                    test -f completions/example.bash
                    grep -q '"initialized": true' template.json
                    if PATH="${fakeGo}/bin:$PATH" bash ./hack/init-template.sh acme-labs sample example; then
                      echo "initializer accepted a second run" >&2
                      exit 1
                    fi
                  )
                fi
                touch "$out"
              '';
        }
      );

      devShells = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              pkgs.go
              pkgs.actionlint
              pkgs.bash
              pkgs.fish
              pkgs.gopls
              pkgs.gotools
              pkgs.go-tools
              pkgs.goreleaser
              pkgs.nushell
              pkgs.ripgrep
              pkgs.shellcheck
              pkgs.shfmt
              pkgs.zsh
            ];
            shellHook = ''
              export GOTOOLCHAIN=local
            '';
          };
        }
      );
    };
}
