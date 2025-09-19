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
}
