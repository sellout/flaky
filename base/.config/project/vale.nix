## Editorial style – https://vale.sh/
{config, lib, ...}: {
  programs.vale = {
    coreSettings = {
      MinAlertLevel = "suggestion";
      Packages = "Microsoft";
      Vocab = config.project.name;
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
        "Microsoft.Ranges" = "NO"; # We use en dashes, not words.
        "Microsoft.Vocab" = "NO"; # Not consistent enough.
        "Microsoft.We" = "NO"; # I _like_ first-person plural.
      };
    };
    excludes = [
      ## We skip licenses because they are written by lawyers, not by us.
      "*/LICENSE"
      ## TODO: Have a general `ignores` list that we can process into
      ##       gitignores, `find -not` lists, etc.
      "*.nix"
      "*/flake.lock"
      "./.cache/*"
      "./.config/mustache.yaml"
      "./.github/workflows/*.yml"
      "./.gitignore"
      "./.vale.ini"
    ];
    vocab.${config.project.name}.accept = [
      "direnv"
      "garnix"
      "[Nn]ix"
      "Pfeil"
      "ShellCheck"
    ];
  };
}
