{
  services.garnix.builds = {
    exclude = [
      ## TODO: This check requires Internet access.
      "checks.*.project-manager-files"
    ];
    include = ["*.*" "*.*.*"];
  };
}
