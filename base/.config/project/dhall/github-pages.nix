{projectName}: {lib, ...}: let
  defaultBranch = "main";
in {
  services.github = {
    settings.pages = {
      build_type = "workflow";
      source.branch = defaultBranch;
    };
    workflow."pages.yml".text = lib.generators.toYAML {} {
      name = "Deploy modules & generated docs to Pages";

      on = {
        # Runs on pushes targeting the default branch
        push.branches = [defaultBranch];
        # Allows you to run this workflow manually from the Actions tab
        workflow_dispatch = null;
      };

      # Sets permissions of the GITHUB_TOKEN to allow deployment to GitHub Pages
      permissions = {
        contents = "read";
        id-token = "write";
        pages = "write";
      };

      # Allow only one concurrent deployment, skipping runs queued between the
      # run in-progress and latest queued. However, do NOT cancel in-progress
      # runs as we want to allow these production deployments to complete.
      concurrency = {
        cancel-in-progress = false;
        group = "pages";
      };

      jobs = {
        build = {
          runs-on = "ubuntu-24.04";
          steps = [
            {
              name = "Checkout";
              uses = "actions/checkout@v4";
            }
            {
              name = "Setup Pages";
              uses = "actions/configure-pages@v4";
            }
            {
              uses = "cachix/install-nix-action@v24";
              "with".extra_nix_config = ''
                extra-trusted-public-keys = cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=
                extra-substituters = https://cache.garnix.io
              '';
            }
            {
              uses = "lriesebos/nix-develop-command@v1";
              "with".command = ''
                dhall-docs \
                  --input ./dhall \
                  --base-import-url "https://sellout.github.io/${projectName}" \
                  --package-name "${projectName}"
                ## We copy here to fix the permissions from the Nix symlinks
                cp -r ./docs ./_site
                chmod --recursive +rwx ./_site
                cp -r ./dhall/* ./_site/
              '';
            }
            {
              name = "Upload artifact";
              uses = "actions/upload-pages-artifact@v3";
            }
          ];
        };
        deploy = {
          environment = {
            name = "github-pages";
            url = "\${{ steps.deployment.outputs.page_url }}";
          };
          runs-on = "ubuntu-24.04";
          needs = "build";
          steps = [
            {
              name = "Deploy to GitHub Pages";
              id = "deployment";
              uses = "actions/deploy-pages@v4";
            }
          ];
        };
      };
    };
  };
}
