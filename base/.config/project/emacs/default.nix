### All available options for this file are listed in
### https://sellout.github.io/project-manager/options.xhtml
{lib, ...}: {
  project.file.".dir-locals.el" = lib.mkDefault {
    minimum-persistence = "worktree";
    ## NB: Emacs doesn’t automatically recognize this as `lisp-data-mode` unless
    ##     it’s named with the leading dot, so we leave it in this case.
    source = ./.dir-locals.el;
  };
}
