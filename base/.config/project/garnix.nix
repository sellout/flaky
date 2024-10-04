{lib, ...}: {
  services.garnix.builds."*" = {
    exclude = [
      ## TODO: Enable once garnix-io/issues#16 is closed.
      "*.x86_64-darwin"
      "*.x86_64-darwin.*"
      ## TODO: Remove once garnix-io/garnix#285 is fixed.
      "homeConfigurations.x86_64-darwin-example"
    ];
    ## NB: This builds everything (except what’s excluded above), so we use
    ##    `lib.mkDefault` since merging any other definition with this would
    ##     be a NOP.
    include = lib.mkDefault ["*.*" "*.*.*"];
  };
}
