{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.services.haskell-ci;

  bounds = ["--prefer-oldest" ""];
in {
  options.services.haskell-ci = {
    enable =
      lib.mkEnableOption "Haskell CI on GitHub"
      // {default = config.services.github.enable;};

    ## TODO: Map `systems` and `exclude` from Nixier values – perhaps flake-utils
    ##       systems, and a bool for `--prefer-oldest`?
    systems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        A list of GitHub system names to run CI against.
      '';
      example = lib.literalMD ''
        ["macos-14" "ubuntu-24.04"]
      '';
    };

    ghcVersions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        A list of GHC version numbers to run CI against.
      '';
      example = lib.literalMD ''
        ["8.10.7" "9.0.2" "9.2.2"]
      '';
    };

    cabalPackages = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = ''
        An attrSet of Cabal package names to run CI again. The value is the
        directory containing the corresponding Cabal file.
      '';
      example = lib.literalMD ''
        {
          yaya = "core";
          yaya-unsafe = "unsafe";
        }
      '';
    };

    ## TODO: Prefer ignoring most known failures once
    ##       https://github.com/orgs/community/discussions/15452 is resolved.
    exclude = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.str);
      default = [];
      description = ''
        A list of matrix entries to exclude from CI. They can have the
        attributes `ghc`, `os`, and `bounds`.
      '';
      example = lib.literalMD ''
        [{os = "macos-14"; ghc = "8.10.7"; bounds = "--prefer-oldest";}]
      '';
    };

    include = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.str);
      default = [];
      description = ''
        A list of builds to add to the matrix. They can have the attributes
        `ghc`, `os`, and `bounds`.
      '';
      example = lib.literalMD ''
        [{os = "macos-14"; ghc = "8.10.7"; bounds = "--prefer-oldest";}]
      '';
    };

    defaultGhcVersion = lib.mkOption {
      type = lib.types.str;
      description = ''
        The version of GHC to use for tools that aggregate data from the builds.
      '';
      example = lib.literalMD ''
        "9.6.5"
      '';
    };

    latestGhcVersion = lib.mkOption {
      type = lib.types.str;
      description = ''
        The version of GHC to use for things that only get built once. We use
        the latest to have things be as up-to-date as possible. E.g., for the
        license report.
      '';
      example = lib.literalMD ''
        "9.10.1"
      '';
    };

    extraDependencyVersions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        A list of Cabal package versions to include in the bounds, even if the
        Cabal solver doesn’t select them. This is useful for supporting older
        versions of packages in the same repo, or version that are in the Nix
        package set, but not selected by the solver on GitHub.
      '';
      example = lib.literalMD ''
        [
          "yaya-0.5.1.0"
          "yaya-0.6.0.0"
          "yaya-hedgehog-0.2.1.0"
          "yaya-hedgehog-0.3.0.0"
          "th-abstraction-0.5.0.0"
        ]
      '';
    };
  };
  config = lib.mkIf cfg.enable (let
    planName = "plan-\${{ matrix.os }}-\${{ matrix.ghc }}\${{ matrix.bounds }}";
    runs-on = "ubuntu-24.04";
    filterGhcVersions = lib.intersectLists cfg.ghcVersions;
  in {
    services.github.workflow."build.yml".text = lib.generators.toYAML {} {
      name = "CI";
      on = {
        push.branches = ["main"];
        pull_request.types = [
          "opened"
          "synchronize"
        ];
      };
      jobs = {
        build = {
          strategy = {
            fail-fast = false;
            matrix = {
              inherit bounds;
              ghc = cfg.ghcVersions;
              os = cfg.systems;
              exclude =
                ## GHCup needs an older Ubuntu for these versions..
                map (ghc: {
                  inherit ghc;
                  os = "ubuntu-24.04";
                }) (filterGhcVersions ["7.10.3" "8.0.2" "8.2.2"])
                ## GitHub can’t install GHC older than 9.4 on macos-14.
                ++ map (ghc: {
                  inherit ghc;
                  os = "macos-14";
                }) (builtins.filter (ghc: lib.versionOlder ghc "9.4")
                  cfg.ghcVersions)
                ++ cfg.exclude;
              include =
                lib.concatMap (bounds:
                  map (ghc: {
                    inherit bounds ghc;
                    os = "ubuntu-22.04";
                  }) (filterGhcVersions ["8.0.2" "8.2.2"]))
                bounds
                ++ cfg.include;
            };
          };
          runs-on = "\${{ matrix.os }}";
          env.CONFIG = "--enable-tests --enable-benchmarks \${{ matrix.bounds }}";
          steps = [
            {uses = "actions/checkout@v4";}
            {
              uses = "haskell-actions/setup@v2";
              id = "setup-haskell-cabal";
              "with" = {
                cabal-version = pkgs.cabal-install.version;
                ghc-version = "\${{ matrix.ghc }}";
              };
            }
            {run = "cabal v2-freeze $CONFIG";}
            {
              uses = "actions/cache@v4";
              "with" = {
                path = ''
                  ''${{ steps.setup-haskell-cabal.outputs.cabal-store }}
                  dist-newstyle
                '';
                key = "\${{ matrix.os }}-\${{ matrix.ghc }}-\${{ hashFiles('cabal.project.freeze') }}";
              };
            }
            ## NB: The `doctests` suites don’t seem to get built without
            ##     explicitly doing so before running the tests.
            {run = "cabal v2-build all $CONFIG";}
            {run = "cabal v2-test all $CONFIG";}
            {run = "mv dist-newstyle/cache/plan.json ${planName}.json";}
            {
              name = "Upload build plan as artifact";
              uses = "actions/upload-artifact@v4";
              "with" = {
                name = planName;
                path = "${planName}.json";
              };
            }
          ];
        };
        check-bounds = {
          inherit runs-on;
          ## Some "build" jobs are a bit flaky. This can give us useful bounds
          ## information even without all of the build plans.
          "if" = "always()";
          needs = ["build"];
          steps = [
            {uses = "actions/checkout@v4";}
            {
              uses = "haskell-actions/setup@v2";
              id = "setup-haskell-cabal";
              "with" = {
                cabal-version = pkgs.cabal-install.version;
                ghc-version = cfg.defaultGhcVersion;
              };
            }
            {
              run = ''
                ## TODO: Remove the manual cloning once cabal-plan-bounds >0.1.5.1
                ##       is released. Currently, it’s needed because of
                ##       nomeata/cabal-plan-bounds#19.
                git clone https://github.com/nomeata/cabal-plan-bounds
                cd cabal-plan-bounds
                cabal install cabal-plan-bounds
              '';
            }
            {
              name = "download Cabal plans";
              uses = "actions/download-artifact@v4";
              "with" = {
                path = "plans";
                pattern = "plan-*";
                merge-multiple = true;
              };
            }
            {
              name = "Cabal plans considered in generated bounds";
              run = "find plans/";
            }
            {
              name = "check if bounds have changed";
              ## TODO: Simplify this once cabal-plan-bounds supports a `--check`
              ##       option.
              run = ''
                diffs="$(find . -name '*.cabal' -exec \
                  cabal-plan-bounds \
                    --dry-run \
                    ${
                  lib.concatMapStrings
                  (pkg: "--also " + pkg + " ")
                  cfg.extraDependencyVersions
                } \
                    plans/*.json \
                    --cabal {} \;)"
                if [[ -n "$diffs" ]]; then
                  echo "$diffs"
                  exit 1
                fi
              '';
            }
          ];
        };
        check-licenses = {
          inherit runs-on;
          ## Some "build" jobs are a bit flaky. Since this only uses one of the
          ## jobs from the matrix, we run it regardless of build failures.
          "if" = "always()";
          needs = ["build"];
          steps = [
            {uses = "actions/checkout@v4";}
            {
              uses = "haskell-actions/setup@v2";
              id = "setup-haskell-cabal";
              "with" = {
                cabal-version = pkgs.cabal-install.version;
                ghc-version = cfg.defaultGhcVersion;
              };
            }
            {run = "cabal install cabal-plan -flicense-report";}
            {
              name = "download Cabal plans";
              uses = "actions/download-artifact@v4";
              "with" = {
                path = "plans";
                pattern = "plan-*";
                merge-multiple = true;
              };
            }
            {
              run = ''
                mkdir -p dist-newstyle/cache
                mv plans/plan-${runs-on}-${cfg.latestGhcVersion}.json dist-newstyle/cache/plan.json
              '';
            }
            {
              name = "check if licenses have changed";
              run = ''
                ${lib.toShellVar "packages" cfg.cabalPackages}
                for package in "''${!packages[@]}"; do
                  {
                    echo "**NB**: This captures the licenses associated with a particular set of dependency versions. If your own build solves differently, it’s possible that the licenses may have changed, or even that the set of dependencies itself is different. Please make sure you run [\`cabal-plan license-report\`](https://hackage.haskell.org/package/cabal-plan) on your own components rather than assuming this is authoritative."
                    echo
                    cabal-plan license-report "$package:lib:$package"
                  } >"''${packages[$package]}/docs/license-report.md"
                done
                git diff --exit-code */docs/license-report.md
              '';
            }
          ];
        };
      };
    };
  });
}
