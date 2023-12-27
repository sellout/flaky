{
  config,
  flaky,
  lib,
  ...
}: {
  services.github = {
    settings = {
      # These settings are synced to GitHub by https://probot.github.io/apps/settings/

      # See https://docs.github.com/en/rest/reference/repos#update-a-repository for all available settings.
      repository = {
        name = config.project.name;
        description = config.project.summary;
        # homepage = "https://example.github.io/";
        private = false;
        has_issues = true;
        has_projects = true;
        has_wiki = true;
        has_downloads = false;
        default_branch = "main";
        allow_squash_merge = false;
        allow_merge_commit = true;
        allow_rebase_merge = false;
        delete_branch_on_merge = true;
        merge_commit_title = "PR_TITLE";
        merge_commit_message = "PR_BODY";
        enable_automated_security_fixes = true;
        enable_vulnerability_alerts = true;
      };

      labels = {
        automated = {
          color = "";
          description = "Created automatically by some service or process";
        };
        bug = {
          color = "#d73a4a";
          description = "Something isn’t working";
        };
        dependencies = {
          color = "#333333";
          description = "Updates or other changes to dependencies";
        };
        documentation = {
          color = "#0075ca";
          description = "Improvements or additions to documentation";
        };
        enhancement = {
          color = "#a2eeef";
          description = "New feature or request";
        };
        "good first issue" = {
          color = "#7057ff";
          description = "Good for newcomers";
        };
        "help wanted" = {
          color = "#008672";
          description = "Extra attention is needed";
        };
        question = {
          color = "#d876e3";
          description = "Further information is requested";
        };
        sponsored = {
          color = "#d4af37"; # gold
          description = "Work prioritized by a sponsor";
        };
      };

      branches = {
        main = {
          # https://docs.github.com/en/rest/branches/branch-protection?apiVersion=2022-11-28#update-branch-protection
          protection = {
            required_pull_request_reviews = null;
            required_status_checks = {
              strict = false;
              contexts = lib.concatMap flaky.lib.garnixChecks [
                (sys: "check formatter [${sys}]")
                (sys: "devShell default [${sys}]")
              ];
            };
            enforce_admins = true;
            required_linear_history = false;
            allow_force_pushes = false;
            restrictions = null;
          };
        };
      };

      ## TODO: This doesn’t seem to actually set the
      ##       Settings→Actions→General→“Allow GitHub Actions to create and
      ##       approve pull requests” checkbox, see repository-settings/app#318.
      actions.permissions.workflow.can_approve_pull_request_reviews = true;
    };
  };
}
