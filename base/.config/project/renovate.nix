{
  config,
  lib,
  ...
}: {
  services.renovate.settings = let
    ## If all checks are expected to be run by CI, then we can allow automerge
    ## to happen after a successful CI run.
    automerge = config.project.unsandboxedChecks == {};
  in {
    labels = ["automated"];
    lockFileMaintenance = {
      inherit automerge;
      enabled = true;
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
      runs-on = "ubuntu-24.04";
      steps = [
        {
          uses = "actions/checkout@v6";
          "with" = {
            repository = "\${{ github.event.pull_request.head.repo.full_name }}";
            ref = "\${{ github.event.pull_request.head.ref }}";
            ## This uses a custom token because with the default GITHUB_TOKEN,
            ## it won’t re-run checks after creating the PR.
            token = "\${{ secrets.PROJECT_MANAGER_TOKEN }}";
          };
        }
        {uses = "cachix/install-nix-action@v31";}
        {
          run = ''
            nix develop .#project-manager \
              --accept-flake-config \
              --command project-manager kitchen-sink
          '';
        }
        {
          name = "commit changes";
          uses = "EndBug/add-and-commit@v9";
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
