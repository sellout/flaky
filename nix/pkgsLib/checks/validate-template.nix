{
  cacert,
  git,
  lib,
  moreutils,
  mustache-go,
  nix,
  project-manager,
  rename,
  self,
  simple,
}: name: src:
(simple
  "validate ${name}"
  src
  [
    cacert
    git
    moreutils
    mustache-go
    nix
    project-manager
    rename
  ]
  ''
    export HOME="$(mktemp --directory --tmpdir fake-home.XXXXXX)"
    mkdir -p "$HOME/.local/state/nix/profiles"

    export NIX_CONFIG=$(cat <<'CONFIG'
    accept-flake-config = true
    extra-experimental-features = flakes nix-command
    CONFIG
    )

    (
      set -o xtrace
      nix flake new --template "$src#${name}" "${name}-example"
      cd "${name}-example"
      find . -iname "*{{project.name}}*" -depth \
        -execdir rename 's/\{\{project.name\}\}/template-example/g' {} +
      find . -type f -exec bash -c \
        'mustache "$src/templates/example.yaml" "$0" | sponge "$0"' \
        {} \;
      ## Reference _this_ version of flaky, rather than a published one.
      ##
      ## NB: There might be a better way, but this is easier than passing
      ##    `--override-input` everywhere.
      sed -i -e 's#"github:sellout/flaky"#"path:${self}"#g' ./flake.nix
      git init
      git add --all
      ## Run `project-manager switch` from either the `default` devShell, the
      ## `project-manager` devShell, or directly (if we can’t find a devShell
      ## with it).
      ##
      ## TODO: Make this more efficient: cascade _only_ if the failure is that
      ##      `project-manager` isn’t found.
      ##nix develop --command project-manager switch "''${FLAKY_ARGS[@]}" \
      ##  || nix develop .#project-manager --command project-manager switch \
      project-manager switch
      ## Format the README before checking, because templating may affect
      ## formatting.
      nix fmt README.md || true
      nix flake check --print-build-logs
    )
  '')
.overrideAttrs (_: {__noChroot = true;})
