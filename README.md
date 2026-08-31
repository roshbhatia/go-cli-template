# go-cli-template

A Nix-first template for small Go command-line tools.

The example keeps stdout machine-readable, writes diagnostics to stderr, and
uses `go-utils` for shared terminal vocabulary.

## Start a project

Create a repository from this template. Then replace the module and binary
names.

```bash
go mod edit -module github.com/OWNER/PROJECT
git mv cmd/example cmd/PROJECT
rg -l 'example|go-cli-template' | xargs sed -i '' -e 's/example/PROJECT/g' -e 's/go-cli-template/PROJECT/g'
go mod tidy
```

## Development

```bash
nix develop
go test -race ./...
nix build
nix flake check
```

## Example

```bash
nix run . -- Roshan
nix run . -- --json Roshan
```
