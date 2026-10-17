{
  imports = [
    ./..
  ];

  ## NOTE: Not the same option as `programs.treefmt.programs.shellcheck` below.
  ##       This module supplies the ShellCheck carrying our directives – which
  ##       Treefmt then uses.
  programs.shellcheck.enable = true;

  programs.treefmt = {
    ## Shell linter
    programs.shellcheck.enable = true;
    ## Shell formatter
    programs.shfmt.enable = true;
  };

  programs.vale.excludes = [
    "*.bash"
    "*.bats"
  ];
}
