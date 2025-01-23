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
}
