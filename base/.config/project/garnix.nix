{
  services.garnix.builds = {
    exclude = [
      ## TODO: Enable once garnix-io/issues#16 is closed.
      "*.x86_64-darwin"
      "*.x86_64-darwin.*"
    ];
    include = ["*.*" "*.*.*"];
  };
}
