{
  ELDEV_LOCAL,
  checkedDrv,
  emacsPackages,
  emacsWithPackages,
  lib,
  stdenv,
}: src: epkgs: let
  emacs = emacsWithPackages (e:
    [
      e.elisp-lint
      e.package-lint
      e.relint
    ]
    ++ epkgs e);
in
  checkedDrv (stdenv.mkDerivation {
    inherit ELDEV_LOCAL src;

    name = "eldev lint";

    nativeBuildInputs = [
      emacs
      emacsPackages.eldev
    ];

    postPatch = lib.elisp.setUpLocalDependencies emacs.deps;

    buildPhase = ''
      runHook preBuild
      ## TODO: Currently needed to make a temp file in
      ##      `eldev--create-internal-pseudoarchive-descriptor`.
      export HOME="$(mktemp --directory --tmpdir fake-home.XXXXXX)"

      ## Need `--external` here so that we don’t try to download any
      ## package archives (which would break the sandbox).
      ## TODO: I'm not sure why this needs `EMACSNATIVELOADPATH`, but it
      ##       does.
      EMACSNATIVELOADPATH= eldev --external lint --required
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      runHook preInstall
    '';
  })
