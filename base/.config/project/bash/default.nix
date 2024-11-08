{
  imports = [
    ./..
  ];

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
