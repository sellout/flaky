{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  cfg = config.services.haskell-ci;

  ## I’m not sure if this is actually GB or GiB – assuming GiB for now.
  githubCacheSize = 10240; # MiB

  ## Whether we can fit Windows’ GHCs into GitHub’s 10 GiB cache alongside
  ## everything else we keep there. We count each job’s store twice, because we
  ## need to keep the previous ones until they’ve all been loaded. Entries saved
  ## by open PRs come out of the remaining 20%, since they’re deleted on close.
  windowsGhcsFit = let
    ghcEntries = prefix:
      lib.length (lib.filter (lib.hasPrefix prefix) cfg.systems)
      * lib.length cfg.ghcVersions;
    jobs =
      lib.length cfg.systems
      * lib.length cfg.ghcVersions
      * 2
      + lib.length cfg.include;
  in
    250
    * ghcEntries "macos"
    + 450 * ghcEntries "windows"
    + 2 * jobs * cfg.cache.storeSize
    <= 0.8 * githubCacheSize;
in {
  options.services.haskell-ci = {
    enable =
      lib.mkEnableOption "Haskell CI on GitHub"
      // {default = config.services.github.enable;};

    ## TODO: Map `systems` and `exclude` from Nixier values – perhaps
    ##       flake-utils systems, and a bool for `--prefer-oldest`?
    systems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        A list of GitHub system names to run CI against.
      '';
      example = with config.services.github.runners.latest; [
        linux-x64
        macos-arm64
      ];
    };

    ghcVersions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        A list of GHC version numbers to run CI against.
      '';
      example = ["8.10.7" "9.0.2" "9.2.2"];
    };

    cabalPackages = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      description = ''
        An attrSet of Cabal package names to run CI against. The value is the
        directory containing the corresponding Cabal file.
      '';
      example = {
        yaya = "core";
        yaya-unsafe = "unsafe";
      };
    };

    allowNewer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Whether to allow ignore upper bounds on local package dependencies.
      '';
    };

    allowOlder = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Whether to allow ignore lower bounds on local package dependencies.
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
      example = [
        {
          os = "macos-14";
          ghc = "8.10.7";
          bounds = "--prefer-oldest";
        }
      ];
    };

    include = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.str);
      default = [];
      description = ''
        A list of builds to add to the matrix. They can have the attributes
        `ghc`, `os`, and `bounds`.
      '';
      example = [
        {
          os = "macos-14";
          ghc = "8.10.7";
          bounds = "--prefer-oldest";
        }
      ];
    };

    defaultGhcVersion = lib.mkOption {
      type = lib.types.str;
      description = ''
        The version of GHC to use for tools that aggregate data from the builds.
      '';
      example = "9.6.5";
    };

    latestGhcVersion = lib.mkOption {
      type = lib.types.str;
      description = ''
        The version of GHC to use for things that only get built once. We use
        the latest to have things be as up-to-date as possible. E.g., for the
        license report.
      '';
      example = "9.10.1";
    };

    extraCabalArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        A list of extra arguments to pass to the `cabal` invocations.
      '';
      example = ["--enable-benchmarks" "--enable-tests"];
    };

    cache = {
      storeSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 50;
        description = ''
          An estimate of one build job’s cached Cabal store, in MiB. It decides
          the default for `cache.windowsGhcs`.
        '';
      };

      windowsGhcs = lib.mkOption {
        type = lib.types.bool;
        default = windowsGhcsFit;
        defaultText = lib.literalMD "whether the estimated cache use fits";
        description = ''
          Whether to cache installed GHCs on Windows. GHCs are always cached on
          macOS, because GitHub charges 10× for macOS minutes.
        '';
      };
    };

    checkBounds = {
      enable = lib.mkEnableOption "checking of dependency bounds";

      extraDependencyVersions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = ''
          A list of Cabal package versions to include in the bounds, even if the
          Cabal solver doesn’t select them. This is useful for supporting older
          versions of packages in the same repo, or version that are in the Nix
          package set, but not selected by the solver on GitHub.
        '';
        example = [
          "yaya-0.5.1.0"
          "yaya-0.6.0.0"
          "yaya-hedgehog-0.2.1.0"
          "yaya-hedgehog-0.3.0.0"
          "th-abstraction-0.5.0.0"
        ];
      };
    };
  };
  config = lib.mkIf cfg.enable (let
    planName = "plan-\${{ matrix.os }}-\${{ matrix.ghc }}\${{ matrix.bounds }}";
    runs-on = config.services.github.runners.latest.linux-x64;
    ## Every key is determined by what the cache holds, so a save only happens
    ## when nothing with the same content is visible. A PR can’t share its
    ## entries with `main` or other PRs, but it only saves what it actually
    ## changed, and `cache-cleanup.yml` deletes those entries when it closes.
    cache = {
      id,
      key,
      path,
      restore-keys ? [],
    }: {
      restore = {
        inherit id;
        uses = "actions/cache/restore@v6";
        "with" =
          {inherit key path;}
          // lib.optionalAttrs (restore-keys != []) {
            restore-keys = lib.concatLines restore-keys;
          };
      };
      save = {
        uses = "actions/cache/save@v6";
        "if" = lib.concatStringsSep " " [
          "\${{ !cancelled()"
          "&& steps.${id}.outcome == 'success'"
          "&& steps.${id}.outputs.cache-hit != 'true' }}"
        ];
        "with" = {
          inherit path;
          key = "\${{ steps.${id}.outputs.cache-primary-key }}";
        };
      };
    };
    ## We trim GHC down as much as possible for caching.
    keepProfiling =
      lib.any (arg: lib.elem arg cfg.extraCabalArgs)
      ["--enable-profiling" "--enable-library-profiling"];
    ghcTrimmings = "no-docs" + lib.optionalString (!keepProfiling) "-or-profiling";
    ghcupDir = "\${{ runner.os == 'Windows' && 'C:/ghcup' || '~/.ghcup' }}";
    ## Installing GHC can take minutes, against seconds loading from a cache.
    ## But each GHC is 150–400 MiB of our 10 GB cache, so use it cautiously.
    ghcCache = cache {
      id = "restore-ghc";
      key = "\${{ matrix.os }}-ghc-\${{ matrix.ghc }}-${ghcTrimmings}";
      path = "${ghcupDir}/ghc/\${{ matrix.ghc }}";
    };
    ## Caches only the Cabal store. `actions/checkout` resets mtimes, so caching
    ## `dist-newstyle` isn’t worth it.
    storeCache = args:
      cache ({
          id = "restore-cabal-store";
          path = "\${{ steps.setup-haskell-cabal.outputs.cabal-store }}";
        }
        // args);
    ## The store holds exactly the plan’s non-local units, so their ids
    ## determine it. A new entry is saved only when the solved plan changes,
    ## and a store for an older plan is restored by prefix to seed the build.
    storeUnits = "dist-newstyle/store-units.txt";
    buildCachePrefix = "\${{ matrix.os }}-\${{ matrix.ghc }}\${{ matrix.bounds }}-build-";
    buildCache = storeCache {
      key = "${buildCachePrefix}\${{ hashFiles('${storeUnits}') }}";
      restore-keys = [buildCachePrefix];
    };
    toolCache = tool: storeCache {key = "${runs-on}-${cfg.defaultGhcVersion}-${tool}";};
  in {
    services.github.workflow."build.yml".text = lib.pm.generators.toYAML {} {
      name = "CI";
      on = {
        push.branches = ["main"];
        pull_request.types = [
          "opened"
          "synchronize"
        ];
      };
      concurrency = {
        group = "\${{ github.workflow }}-\${{ github.ref || github.run_id }}";
        cancel-in-progress = true;
      };
      jobs = let
        ## NB: This uses haskell-actions/setup instead of haskell/ghcup-setup
        ##     primarily because of haskell/ghcup-setup#18.
        setUpHaskell = ghc-version: {
          uses = "haskell-actions/setup@v2";
          id = "setup-haskell-cabal";
          "with" = {
            inherit ghc-version;
            cabal-version = pkgs.cabal-install.version;
          };
        };
      in {
        build = {
          strategy = {
            fail-fast = false;
            matrix = {
              inherit (cfg) exclude include;
              bounds = ["" "--prefer-oldest"];
              ghc = cfg.ghcVersions;
              os = cfg.systems;
            };
          };
          runs-on = "\${{ matrix.os }}";
          ## Windows defaults to PowerShell, where `$CONFIG` doesn’t work.
          defaults.run.shell = "bash";
          env.CONFIG = let
            packages = lib.concatStringsSep "," (map (name: "${name}:all") (lib.attrNames cfg.cabalPackages));
            bounds =
              (
                if cfg.allowNewer
                then [("--allow-newer=" + packages)]
                else []
              )
              ++ (
                if cfg.allowOlder
                then [("--allow-older=" + packages)]
                else []
              );
          in
            lib.concatStringsSep " " (cfg.extraCabalArgs ++ bounds) + " \${{ matrix.bounds }}";
          ## `{}` marks a step this configuration doesn’t use.
          steps = lib.filter (step: step != {}) [
            ## Workaround for
            ## https://stackoverflow.com/questions/37948715/why-executables-built-with-ghc-7-10-2-have-dependencies-with-both-librt-and-libc
            {
              "if" = "\${{ matrix.ghc == '7.10.3' && matrix.os == 'ubuntu-22.04' }}";
              run = ''
                sudo ln -s /lib/x86_64-linux-gnu/libdl.so.2 /usr/lib/x86_64-linux-gnu/libdl.so
                sudo ln -s /lib/x86_64-linux-gnu/libpthread.so.0 /usr/lib/x86_64-linux-gnu/libpthread.so
                sudo ln -s /lib/x86_64-linux-gnu/librt.so.1 /usr/lib/x86_64-linux-gnu/librt.so
                sudo ln -s /lib/x86_64-linux-gnu/libutil.so.1 /usr/lib/x86_64-linux-gnu/libutil.so
              '';
            }
            ## GHC 9.4–9.8 link with `-fuse-ld=gold`, but Ubuntu 26.04 no longer
            ## installs gold by default.
            {
              name = "install ld.gold";
              "if" = lib.concatStringsSep " " [
                "\${{ runner.os == 'Linux'"
                "&& (startsWith(matrix.ghc, '9.4.')"
                "|| startsWith(matrix.ghc, '9.6.')"
                "|| startsWith(matrix.ghc, '9.8.')) }}"
              ];
              run = ''
                sudo apt-get update
                sudo apt-get install --yes binutils-gold
              '';
            }
            ## WAIT: Work around the broken macOS runner.
            ##       (actions/runner-images#14940).
            {
              name = "use the Command Line Tools linker";
              "if" = "\${{ runner.os == 'macOS' && runner.arch == 'ARM64' }}";
              run = "sudo xcode-select -s /Library/Developer/CommandLineTools";
            }
            {uses = "actions/checkout@v7";}
            (lib.optionalAttrs cfg.cache.windowsGhcs {
              ## Don’t spend cache on GHCs the runner image already has.
              name = "check for a preinstalled GHC";
              id = "preinstalled-ghc";
              "if" = "\${{ runner.os == 'Windows' }}";
              run = ''
                if [[ -d C:/ghcup/ghc/''${{ matrix.ghc }} ]]; then
                  echo found=true >>"$GITHUB_OUTPUT"
                fi
              '';
            })
            ## Installing GHC takes minutes – 4–10 on macOS, which costs 10×
            ## what Linux does on non-free builds.
            (ghcCache.restore
              // {
                "if" =
                  if cfg.cache.windowsGhcs
                  then
                    lib.concatStringsSep " " [
                      "\${{ runner.os == 'macOS'"
                      "|| (runner.os == 'Windows'"
                      "&& steps.preinstalled-ghc.outputs.found != 'true') }}"
                    ]
                  else "\${{ runner.os == 'macOS' }}";
              })
            ## haskell-actions/setup only treats a GHC as installed when
            ## ~/.ghcup/bin/ exists, so create it. (Windows runners have ghcup.)
            {
              name = "use the restored GHC";
              "if" = lib.concatStringsSep " " [
                "\${{ runner.os == 'macOS'"
                "&& steps.restore-ghc.outputs.cache-hit == 'true' }}"
              ];
              run = "mkdir -p ~/.ghcup/bin";
            }
            (setUpHaskell "\${{ matrix.ghc }}")
            {
              name = "trim GHC (${ghcTrimmings})";
              "if" = lib.concatStringsSep " " [
                "\${{ steps.restore-ghc.outcome == 'success'"
                "&& steps.restore-ghc.outputs.cache-hit != 'true' }}"
              ];
              run =
                ''
                  ghc_dir=${ghcupDir}/ghc/''${{ matrix.ghc }}
                  du -sh "$ghc_dir"
                  rm -rf "$ghc_dir/share/doc" "$ghc_dir/doc"
                ''
                + lib.optionalString (!keepProfiling) ''
                  find "$ghc_dir" \( -name '*.p_hi' -o -name '*_p.a' -o -name '*.p_o' \) -delete
                ''
                + ''
                  du -sh "$ghc_dir"
                '';
            }
            ghcCache.save
            ## This figures out the subset of non-local packages we actually
            ## need, which gives us a much more consistent result than a freeze
            ## file, which captures the whole index.
            {
              name = "list the units the store needs";
              run = ''
                cabal v2-build all $CONFIG --dry-run
                jq -r '."install-plan"[] | select(.style != "local") | .id' \
                  dist-newstyle/cache/plan.json \
                  | sort >${storeUnits}
              '';
            }
            buildCache.restore
            ## NB: The `doctests` suites don’t seem to get built without
            ##     explicitly doing so before running the tests.
            {run = "cabal v2-build all $CONFIG";}
            {run = "cabal v2-test all $CONFIG";}
            buildCache.save
            {run = "mv dist-newstyle/cache/plan.json ${planName}.json";}
            {
              name = "Upload build plan as artifact";
              uses = "actions/upload-artifact@v7";
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
          "if" = "\${{ !cancelled() }}";
          needs = ["build"];
          steps = [
            {uses = "actions/checkout@v7";}
            (setUpHaskell cfg.defaultGhcVersion)
            (toolCache "cabal-plan-bounds").restore
            {run = "cabal install cabal-plan-bounds";}
            (toolCache "cabal-plan-bounds").save
            {
              name = "download Cabal plans";
              uses = "actions/download-artifact@v8";
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
              continue-on-error = !cfg.checkBounds.enable;
              ## TODO: Simplify this once cabal-plan-bounds supports a `--check`
              ##       option (nomeata/cabal-plan-bounds#26).
              run = ''
                diffs="$(find . -name '*.cabal' -exec \
                  cabal-plan-bounds \
                    --dry-run \
                    ${
                  lib.concatMapStrings
                  (pkg: "--also " + pkg + " ")
                  cfg.checkBounds.extraDependencyVersions
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
          "if" = "\${{ !cancelled() }}";
          needs = ["build"];
          steps = [
            {
              uses = "actions/checkout@v7";
              "if" = "github.event_name != 'pull_request'";
            }
            {
              uses = "actions/checkout@v7";
              "if" = "github.event_name == 'pull_request'";
              "with" = {
                repository = "\${{ github.event.pull_request.head.repo.full_name }}";
                ref = "\${{ github.event.pull_request.head.ref }}";
                ## TODO: I don’t know why we can’t push without this token.
                token = "\${{ secrets.PROJECT_MANAGER_TOKEN }}";
              };
            }
            (setUpHaskell cfg.defaultGhcVersion)
            (toolCache "cabal-plan").restore
            {
              run = ''
                cabal install cabal-plan \
                  --flags='exe license-report' \
                  --ghc-options='-Wwarn'
              '';
            }
            (toolCache "cabal-plan").save
            {
              name = "download Cabal plans";
              uses = "actions/download-artifact@v8";
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
              name = "update license reports";
              run = ''
                ${lib.toShellVar "packages" cfg.cabalPackages}
                for package in "''${!packages[@]}"; do
                  {
                    echo "**NB**: This captures the licenses associated with a particular set of dependency versions. If your own build solves differently, it’s possible that the licenses may have changed, or even that the set of dependencies itself is different. Please make sure you run [\`cabal-plan license-report\`](https://hackage.haskell.org/package/cabal-plan) on your own components rather than assuming this is authoritative."
                    echo
                    cabal-plan license-report "$package:lib:$package"
                  } >"''${packages[$package]}/docs/license-report.md"
                done
              '';
            }
            {
              name = "check changes";
              "if" = "github.event_name != 'pull_request'";
              run = "git diff --exit-code */docs/license-report.md";
            }
            {
              name = "commit changes";
              "if" = "github.event_name == 'pull_request'";
              uses = "EndBug/add-and-commit@v10";
              "with" = {
                add = "*/docs/license-report.md";
                default_author = "github_actions";
                message = "Update license reports";
                push = "origin --no-verify --set-upstream";
              };
            }
          ];
        };
      };
    };
    ## Once a PR closes, its caches are dead, and leaving them around can
    ## potentially lead to the default branch’s caches being evicted, so we
    ## remove ’em.
    services.github.workflow."cache-cleanup.yml".text = lib.pm.generators.toYAML {} {
      name = "cache cleanup";
      on.pull_request_target.types = ["closed"];
      permissions.actions = "write";
      jobs.cleanup = {
        inherit runs-on;
        steps = [
          {
            name = "delete the closed PR’s caches";
            env = {
              GH_REPO = "\${{ github.repository }}";
              GH_TOKEN = "\${{ github.token }}";
            };
            run = ''
              gh cache delete \
                --all \
                --ref refs/pull/''${{ github.event.pull_request.number }}/merge \
                --succeed-on-no-caches
            '';
          }
        ];
      };
    };
  });
}
