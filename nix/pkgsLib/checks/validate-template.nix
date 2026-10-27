{
  git,
  lib,
  moreutils,
  mustache-go,
  nix,
  project-manager,
  rename,
  runStrictCommand,
  self,
  stdenv,
}: {
  ## Bash to run in the instantiated project before its placeholders are
  ## substituted and it’s checked – for example, to create empty directories,
  ## which Git can’t track.
  setup ? "",
  ## Flake inputs of the instantiated project to replace with the given sources
  ## (for example, `{project-manager = self;}`), so that the template is checked
  ## against the versions under test rather than published ones. Flaky itself is
  ## always replaced with this version.
  overrideInputs ? {},
}: name: src: let
  allOverrides = {flaky = self;} // overrideInputs;
  overrides =
    lib.concatStringsSep " "
    (lib.mapAttrsToList (input: source:
      "--override-input ${lib.escapeShellArg input} "
      + lib.escapeShellArg "path:${source}")
    allOverrides);
  ## Recursive Nix can only see store paths that are inputs of this build, so
  ## this treats all transitive flaky-environment inputs as inputs to let the
  ## check run without network access. It’s keyed by source so that cycles (for
  ## example, between Flaky and Project Manager) terminate.
  lockedInputs = let
    entries = flake:
      map (input: {
        inherit input;
        key = toString input.outPath;
      }) (lib.attrValues (flake.inputs or {}));
  in
    map (entry: entry.key) (builtins.genericClosure {
      startSet = lib.concatMap entries ([src] ++ lib.attrValues allOverrides);
      operator = entry: entries entry.input;
    });
in
  runStrictCommand "validate ${name}" (
    {
      inherit lockedInputs src;
      nativeBuildInputs = [
        git
        moreutils
        mustache-go
        nix
        project-manager
        rename
      ];
      requiredSystemFeatures = ["recursive-nix"];
    }
    ## WAIT: The Darwin sandbox doesn’t let a build read the store paths that
    ##       its recursive Nix calls add. (NixOS/nix#16708)
    // lib.optionalAttrs stdenv.buildPlatform.isDarwin {__noChroot = true;}
  )
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
      ${setup}
      find . -iname "*{{project.name}}*" -depth \
        -execdir rename 's/{{project.name}}/template-example/g' {} +
      find . -type f -exec bash -c \
        'mustache "$src/templates/example.yaml" "$0" | sponge "$0"' \
        {} \;
      git init
      git add --all
      ## Lock the inputs under test to their local sources.
      nix flake lock ${overrides}
      ## The lock file may be new, so add it again.
      git add --all
      ## Run `project-manager switch` from either the `default` devShell, the
      ## `project-manager` devShell, or directly (if we can’t find a devShell
      ## with it).
      ##
      ## TODO: Make this more efficient: cascade _only_ if the failure is that
      ##      `project-manager` isn’t found.
      # nix develop --command project-manager switch "''${FLAKY_ARGS[@]}" \
      #   || nix develop .#project-manager --command project-manager switch \
      project-manager switch
      ## Format the README before checking, because templating may affect
      ## formatting.
      nix fmt README.md || true
      nix flake check --print-build-logs
    )
    touch "$out"
  ''
