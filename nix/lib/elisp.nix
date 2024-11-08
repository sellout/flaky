{
  emacsPath = package: "${package}/share/emacs/site-lisp/elpa/${package.pname}-${package.version}";

  overlays.default = emacsOverlay: final: prev: {
    emacsPackagesFor = emacs:
      (prev.emacsPackagesFor emacs).overrideScope
      (emacsOverlay final prev);
  };

  ## Read version in format: ;; Version: x.y(.z)?
  readVersion = fp:
    builtins.head
    (builtins.match
      ".*;; Version: *([[:digit:]]+\.[[:digit:]]+(\.[[:digit:]]+)?).*"
      (builtins.readFile fp));

  ## Ideally this could just
  ##     (setq eldev-external-package-dir "${deps}/share/emacs/site-lisp/elpa")
  ## but Eldev wants to write to that directory, even if there's nothing to
  ## download.
  setUpLocalDependencies = deps: ''
    {
      echo
      echo "(mapcar 'eldev-use-local-dependency"
      echo "        (condition-case err"
      echo "            (directory-files \"${deps}/share/emacs/site-lisp/elpa\""
      echo "                             t"
      echo "                             directory-files-no-dot-files-regexp)"
      echo "          (error (warn \"%s\" err)"
      echo "             '())))"
    } >> Eldev
  '';
}
