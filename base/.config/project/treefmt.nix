{pkgs, ...}: {
  programs.treefmt = {
    projectRootFile = "flake.nix";
    programs = {
      ## Nix formatter
      alejandra.enable = true;
      dhall.lint = true;
      ## language agnostic line sorter
      ## (https://github.com/google/keep-sorted#readme)
      keep-sorted.enable = true;
      ## Web/JSON/Markdown/TypeScript/YAML formatter
      prettier.enable = pkgs.stdenv.hostPlatform.system != "i686-linux";
      ## Shell formatter
      ## NB: This has to be unset to allow the .editorconfig settings to be
      ##     used. See numtide/treefmt-nix#96.
      shfmt.indent_size = null;
    };
    ## Require files that don’t match any formatter to be listed in `excludes`.
    settings.global.on-unmatched = "error";
  };
}
