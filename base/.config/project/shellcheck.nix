{pkgs, ...}: {
  programs.shellcheck.directives.disable = [
    # Unicode quotes are good, and ShellCheck gets this wrong a lot.
    "SC1111"
    "SC1112"
    # `shfmt` likes to replace `"\$foo"` with '$foo', which then triggers this
    # complaint, so let shfmt do what it wants.
    "SC2016"
  ];
}
