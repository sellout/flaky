githubSystems: {
  lib,
  pkgs,
  self,
  ...
}: let
  planName = "plan-\${{ runner.os }}-\${{ matrix.ghc }}\${{ matrix.bounds }}";
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
            bounds = ["--prefer-oldest" ""];
            ghc = self.lib.nonNixTestedGhcVersions;
            os = githubSystems;
            exclude = [
              ## GHCup can’t find this version for Linux.
              {
                ghc = "7.10.3";
                os = "ubuntu-22.04";
              }
            ];
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
              key = "\${{ runner.os }}-\${{ matrix.ghc }}-\${{ hashFiles('cabal.project.freeze') }}";
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
        runs-on = "ubuntu-22.04";
        needs = ["build"];
        steps = [
          {uses = "actions/checkout@v4";}
          {
            ## TODO: Uses deprecated Node.js, see haskell-actions/setup#72
            uses = "haskell-actions/setup@v2";
            id = "setup-haskell-cabal";
            "with" = {
              ## NB: `cabal-plan-bounds` doesn’t yet support GHC 9.8.
              ghc-version = "9.6.3";
              cabal-version = pkgs.cabal-install.version;
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
                self.lib.extraDependencyVersions or []
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
    };
  };
}
