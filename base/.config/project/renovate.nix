{
  config,
  lib,
  self,
  ...
}: {
  services.renovate.settings = let
    ## If all checks are expected to be run by CI, then we can allow automerge
    ## to happen after a successful CI run.
    automerge = let
      ## For each enabled CI service, the checks it can’t build.
      ## NOTE: Explicit `== true` because this value can be `null`.
      unbuildable =
        lib.optional (config.services.nix-ci.enable == true)
        config.services.nix-ci.unbuildableChecks
        ++ lib.optional config.services.garnix.enable
        config.services.garnix.unbuildableChecks;
      ## The checks that no enabled CI service builds (which is all of them if
      ## no CI service is enabled).
      unbuilt =
        lib.foldl' (acc: checks: builtins.intersectAttrs checks acc)
        config.project.checks
        unbuildable;
    in
      unbuilt == {};

    ## Sources that we either want to track closely or don’t change very often,
    ## and thus shouldn’t restricte the lock file updates.
    slowSources = [
      {owner = "nix-systems";}
      {
        owner = "numtide";
        repo = "flake-utils";
      }
      {owner = "sellout";}
    ];

    ## Whether an input matches one of our slow sources.
    isSlow = original:
      lib.any (source:
        lib.all (attr: lib.toLower (original.${attr} or "") == source.${attr})
        (lib.attrNames source))
      slowSources;

    ## The set of inputs that aren’t slow – Nixpkgs is the main one here, but
    ## plenty of other things like Homebrew casks, etc. fall into this bucket.
    fastInputs = let
      lockFile = "${self}/flake.lock";
      lock = lib.importJSON lockFile;
    in
      if builtins.pathExists lockFile
      then
        lib.attrNames (lib.filterAttrs (_: input:
          lib.isString input && !isSlow lock.nodes.${input}.original or {})
        lock.nodes.root.inputs or {})
      else [];
  in {
    labels = ["automated"];
    lockFileMaintenance = {
      inherit automerge;
      enabled = true;
      ## When there are no fast-changing inputs, we let Renovate update the lock
      ## file as frequently as possible, so we stay in sync with latest
      ## versions. When there are fast-changing inputs, we slow it down to
      ## weekly.
      schedule =
        if fastInputs == []
        then ["* * * * *"]
        else ["* 2-6 * * 0"];
      timezone = "America/Denver";
    };
    packageRules =
      if automerge
      then [
        {
          automerge = true;
          ## Don’t automerge updates of pre-release software.
          matchCurrentVersion = "!/^0/";
          ## Only automerge non-major version updates.
          matchUpdateTypes = ["minor" "patch"];
        }
      ]
      else [];
    platformAutomerge = true;
  };

  ## When Renovate opens a lock file update, run `project-manager switch` and
  ## push the new commit to the PR branch.
  ##
  ## NB: This requires a GitHub PAT (added as an environment secret named
  ##     “PROJECT_MANAGER_TOKEN”) in order to work (otherwise it wouldn’t re-run
  ##     the checks). Technically the PAT only requires write access to
  ##     “Content”, but if you generate GitHub workflows (like this one) via
  ##     Project Manager, you’ll also want write access to “Workflows”. PATs can
  ##     be edited after they’re created, though, so if you’re unsure, you can
  ##     avoid the “Workflows” permission until it causes a failure.
  services.github.workflow."switch-pm-generation.yml".text = lib.pm.generators.toYAML {} {
    name = "Project Manager";
    ## NB: Need `_target` so PRs from forks have access to the PAT that allows
    ##     re-running checks.
    on.pull_request_target = {};
    jobs.switch = {
      ## `maintainer_can_modify` is apparently only ever `true` on forks, so
      ## first check whether the PR is from the same repo.
      "if" = "\${{ github.event.pull_request.head.repo.full_name == github.repository || github.event.pull_request.maintainer_can_modify }}";
      runs-on = config.services.github.runners.latest.linux-x64;
      steps = [
        {
          uses = "actions/checkout@v7";
          "with" = {
            repository = "\${{ github.event.pull_request.head.repo.full_name }}";
            ref = "\${{ github.event.pull_request.head.ref }}";
            ## This uses a custom token because with the default GITHUB_TOKEN,
            ## it won’t re-run checks after creating the PR.
            token = "\${{ secrets.PROJECT_MANAGER_TOKEN }}";
          };
        }
        {
          uses = "cachix/install-nix-action@v31";
          "with" =
            ## This taken allows us to read private repos (which may be used as
            ## flake inputs). Since we shouldn’t have private inputs on public
            ## repos, only add this to private repos.
            if config.services.github.settings.repository.private
            then {
              extra_nix_config = ''
                access-tokens = github.com=''${{ secrets.PROJECT_MANAGER_TOKEN }}
              '';
            }
            else {};
        }
        {
          run = ''
            nix develop .#project-manager \
              --accept-flake-config \
              --command project-manager kitchen-sink
          '';
        }
        {
          name = "commit changes";
          uses = "EndBug/add-and-commit@v10";
          "with" = {
            add = "--all";
            default_author = "github_actions";
            message = "Switch Project Manager generation";
            push = "origin --no-verify --set-upstream";
          };
        }
      ];
    };
  };
}
