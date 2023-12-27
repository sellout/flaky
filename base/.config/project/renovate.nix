{
  ## Currently there is no trivial way to run a command before the PR with
  ## either Renovate or DeterminateSystems/update-flake-lock. The former because
  ## `postUpgradeTasks` can only be used on self-hosted instances
  ## (https://docs.renovatebot.com/configuration-options/#postupgradetasks) and
  ## the latter because of DeterminateSystems/update-flake-lock#91. Until one of
  ## those things changes (or another approach presents itself), this is the
  ## simpler implementation.
  services.renovate.settings.lockFileMaintenance.enabled = true;
}
