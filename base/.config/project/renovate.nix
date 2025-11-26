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
  services.github.workflow."switch-pm-generation.yml".text = lib.pm.generators.toYAML {} {
    name = "Project Manager";
    on.pull_request = {};
    jobs.switch = {
      "if" = "github.head_ref == 'renovate/lock-file-maintenance'";
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
        {run = "nix develop .#project-manager --accept-flake-config --command project-manager kitchen-sink";}
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
