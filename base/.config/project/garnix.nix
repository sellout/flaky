{
  config,
  lib,
  ...
}: {
  services.garnix.builds."*" = {
    exclude = [
      ## TODO: Remove once garnix-io/issues#16 is fixed.
      "*.x86_64-darwin"
      "*.x86_64-darwin.*"
      ## TODO: Remove once garnix-io/issues#94 is fixed.
      "*.x86_64-darwin-example"
    ];
    ## NB: This builds everything (except what’s excluded above), so we use
    ##    `lib.mkDefault` since merging any other definition with this would
    ##     be a NOP.
    include = lib.mkDefault ["*.*" "*.*.*"];
  };

  ## https://docs.github.com/en/rest/branches/branch-protection?apiVersion=2022-11-28#update-branch-protection
  services.github.settings.branches.${config.services.github.settings.repository.default_branch}.protection.required_status_checks =
    lib.mkIf config.services.garnix.enable {contexts = ["All Garnix checks"];};
}
