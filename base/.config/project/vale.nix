## Editorial style – https://vale.sh/
{bash-strict-mode, config, lib, pkgs, ...}: let
  ## Stored in the cache because we entirely repopulate it via generation.
  ##
  stylesPath = ".cache/vale";
in {
  programs.vale = {
    coreSettings = {
      MinAlertLevel = "suggestion";
      Packages = "Microsoft";
      StylesPath = stylesPath;
    };
    formatSettings = {
      "*" = {
        BasedOnStyles = lib.concatStringsSep ", " [
          "Vale"
          "Microsoft"
        ];
        ## TODO: In the module, do two things:
        ##    1. convert `true`/`false` to `"YES"`/"`NO"` and
        ##    2. convert deeper attrSets to dot-separated strings.
        "Microsoft.Dashes" = "NO"; # En dashes _should_ have spaces around them.
        "Microsoft.GeneralURL" = "NO"; # Not writing for a general audience.
        "Microsoft.Headings" = "NO"; # Headings aren’t necessarily sentences.
        "Microsoft.Quotes" = "NO"; # Punctuation inside quotes is an abomination.
        "Microsoft.Vocab" = "NO"; # Not consistent enough.
        "Microsoft.We" = "NO"; # I _like_ first-person plural.
      };
    };
    excludes = [
      ## We skip licenses because they are written by lawyers, not by us.
      "*/LICENSE"
      ## TODO: Have a general `ignores` list that we can process into
      ##       gitignores, `find -not` lists, etc.
      "./.cache/*"
      "*/flake.lock"
      ];
  };
}
