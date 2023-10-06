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
        topics = ["hacktoberfest"];
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

      labels = [
        { name = "bug";
          color = "#d73a4a";
          description = "Something isn’t working";
        }
        { name = "documentation";
            color = "#0075ca";
            description = "Improvements or additions to documentation";
        }
        { name = "enhancement";
          color = "#a2eeef";
          description = "New feature or request";
        }
        { name = "good first issue";
          color = "#7057ff";
          description = "Good for newcomers";
        }
        { name = "hacktoberfest-accepted";
          color = "#ff7518"; # pumpkin
          description = "Indicates acceptance for Hacktoberfest criteria, even if not merged yet";
        }
        { name = "help wanted";
          color = "#008672";
          description = "Extra attention is needed";
        }
        { name = "question";
          color = "#d876e3";
          description = "Further information is requested";
        }
        { name = "spam";
          color = "#ffc0cb"; # pink
          description = "Topic created in bad faith. Services like Hacktoberfest use this to identify bad actors";
        }
      ];

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
            restrictions.apps = [];
          };
        };
      };
    };
  };
}
