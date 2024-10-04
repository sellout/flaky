{
  config,
  lib,
  ...
}: {
  imports = [
    ./..
    (import ./github-pages.nix {projectName = config.project.name;})
  ];

  programs = {
    ## Treat all files in the “/dhall/” directory as Dhall files, no extension
    ## needed.
    git.attributes = ["/dhall/** linguist-language=Dhall"];
    treefmt = {
      programs.dhall.enable = true;
      settings.formatter.dhall.includes = ["dhall/*"];
    };
    vale = {
      excludes = ["./dhall/*"];
      vocab.${config.project.name}.accept = [
        "Dhall"
      ];
    };
  };

  services.github.settings.repository.homepage =
    lib.mkDefault "https://sellout.github.io/${config.project.name}";
}
