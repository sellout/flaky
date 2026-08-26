## Editorial style – https://vale.sh/
{
  config,
  lib,
  ...
}: {
  programs.vale = {
    coreSettings = {
      MinAlertLevel = "suggestion";
      Packages = lib.concatStringsSep ", " [
        "alex"
        "Google"
        "Microsoft"
        "proselint"
        "https://github.com/vale-cli/readability/releases/download/v0.1.1/Readability.zip"
        "write-good"
      ];
      Vocab = config.project.name;
    };
    formatSettings = let
      ## NOTE: These don’t cascade, so we have to duplicate them for each glob..
      commonSettings = {
        ## TODO: In the module, do two things:
        ##    1. convert `true`/`false` to `"YES"`/"`NO"` and
        ##    2. convert deeper attrSets to dot-separated strings.
        "Google.DateFormat" = "NO"; # We prefer ‘%Y-%m-%d’
        "Google.EmDash" = "NO"; # Complains about spaced en-dashes, too.
        "Google.Headings" = "NO"; # Headings aren’t necessarily sentences.
        "Google.Quotes" = "NO"; # Punctuation inside quotes is an abomination.
        "Google.We" = "NO"; # I _like_ first-person plural.
        "Microsoft.Dashes" = "NO"; # En dashes _should_ have spaces around them.
        "Microsoft.GeneralURL" = "NO"; # Not writing for a general audience.
        "Microsoft.Headings" = "NO"; # Headings aren’t necessarily sentences.
        "Microsoft.Quotes" = "NO"; # Punctuation inside quotes is an abomination.
        "Microsoft.Vocab" = "NO"; # Not consistent enough.
        "Microsoft.We" = "NO"; # I _like_ first-person plural.
      };
      commonStyles = [
        "alex"
        "Google"
        "Microsoft"
        "proselint"
        "Vale"
        "write-good"
      ];
    in {
      "*" =
        commonSettings
        // {BasedOnStyles = lib.concatStringsSep ", " commonStyles;};
      "**/README.*" =
        commonSettings
        // {
          BasedOnStyles =
            lib.concatStringsSep ", " (commonStyles ++ ["Readability"]);
        };
    };
    excludes = [
      ## We skip licenses because they are written by lawyers, not by us.
      "**/LICENSE"
      "**/LICENSE.*"
      ## TODO: Have a general `ignores` list that we can process into
      ##       gitignores, `find -not` lists, etc.
      "**/*.nix"
      "**/*.yaml"
      "**/*.yml"
      "**/.dir-locals.el"
      "**/flake.lock"
      "./.cache/*"
      "./.config/mustache.yaml"
      "./.github/renovate.json"
      "./.github/settings.yml"
      "./.github/workflows/*.yml"
      "./.gitattributes"
      "./.gitignore"
      "./.vale.ini"
    ];
    vocab.${config.project.name}.accept = [
      "direnv"
      "formatter"
      "[Nn]ix"
      "Pfeil"
      "ShellCheck"
    ];
  };
}
