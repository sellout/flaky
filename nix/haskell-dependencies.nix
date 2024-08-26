### This module tries to get a consistent set of Haskell packages that work
### everywhere.
###
### Tests should be disabled as tightly as possible, but we should try to use
### the same version of a package across all systems & compilers.
final: prev: hfinal: hprev:
(
  if final.lib.versionAtLeast hprev.ghc.version "9.10.0"
  then {
    ChasingBottoms =
      final.haskell.lib.overrideCabal
      hprev.ChasingBottoms {
        editedCabalFile = "PsuYWFTvDZ5jwqiBwsMF8OYZyPFQCRWL4XARvF+0zYo=";
        revision = "1";
        sha256 = "vuzRlfSR/RcjYgXQD4gu521r2Re/EENQ31enBeyJt2Y=";
      };
    ## Earlier versions are too restrictive on `base`.
    base64 = final.haskell.lib.overrideCabal hprev.base64 {
      editedCabalFile = null;
      sha256 = "eUIjnxgElF/W0xmpU/JsU7ZFGAds0pQUH9qYPy/xsrY=";
      version = "1.0";
    };
    ## Earlier versions are too restrictive on `base`.
    boring = hfinal.boring_0_2_2;
    ## Earlier versions are too restrictive on `base`.
    cabal-doctest =
      final.haskell.lib.overrideCabal
      hprev.cabal-doctest {
        editedCabalFile = null;
        sha256 = "gcrQ/EhhVyncvuw+zRK7QpdX8pmsrRS5LvC5VxA+lNM=";
        version = "1.0.10";
      };
    ## This is the latest version, but test suites fail (and also fail
    ## on older versions).
    call-stack = final.haskell.lib.dontCheck hprev.call-stack;
    ## Earlier versions are too restrictive on `base`.
    co-log-core = final.haskell.lib.overrideCabal hprev.co-log-core {
      editedCabalFile = null;
      sha256 = "97JhkWrdYPZRq8bxcEAqbnUELuRIj5SkCtiKlxpxzcc=";
      version = "0.3.2.2";
    };
    ## Earlier versions are too restrictive on `base`.
    commutative-semigroups =
      final.haskell.lib.overrideCabal
      hprev.commutative-semigroups {
        editedCabalFile = null;
        patches = [];
        sha256 = "4uBVoGWG581YoVWw2j4NSdjMBvuUH6qNFMGuVo33ttw=";
        version = "0.2.0.1";
      };
    ## Earlier versions fail tests and are too restrictive on `ghc`.
    doctest = final.haskell.lib.overrideCabal hprev.doctest {
      editedCabalFile = null;
      sha256 = "4r/FouY3sgfbFhbkiAKNm4PoXXdJ20G0bmamgKVGSFw=";
      version = "0.22.3";
    };
    ## Earlier versions are too restrictive on `Cabal`.
    doctest-parallel =
      final.haskell.lib.overrideCabal
      hprev.doctest-parallel {
        editedCabalFile = "VaheuX8Cjum8iJYRFVnwTaACnFlxD59L76KRHUn8VNA=";
        revision = "1";
        sha256 = "ik95fZ8ZWswN5z52OF2xMERQOixCXH0ExHoTAYAA8/Y=";
      };
    ## Earlier versions are too restrictive on `base`.
    extensions = final.haskell.lib.overrideCabal hprev.extensions {
      editedCabalFile = null;
      sha256 = "7Z1GRTIaDmkf5CKyk9HiUJ+zYX7XgPqo2SwOprPDQeU=";
      version = "0.1.0.2";
    };
    ## Earlier versions are too restrictive on `base`.
    ghc-trace-events =
      final.haskell.lib.overrideCabal
      hprev.ghc-trace-events {
        editedCabalFile = null;
        sha256 = "6afff442G4ouUJsYB0B8RlTxanNWQtVOhcjJQ/5B0wU=";
        version = "0.1.2.9";
      };
    ## This is the version for this compiler.
    ghc-lib-parser =
      final.haskell.lib.overrideCabal
      hprev.ghc-lib-parser {
        editedCabalFile = null;
        sha256 = "N9HfXP5D3USDxl3FfFIs2wRsju3cu/2MyqW/5bDW8Tk=";
        version = "9.10.1.20240511";
      };
    ## Otherwise `hashable` picks up a version of `os-string`
    ## different from GHC’s.
    hashable = hprev.hashable.override {os-string = null;};
    ## Earlier revisions are too restrictive on `containers` &
    ## `template-haskell`.
    hedgehog = final.haskell.lib.overrideCabal hprev.hedgehog {
      editedCabalFile = "2Lyqz+kAo0cEa8fDBHtZaR+NRdO4B1U7xOwEvE4R2oE=";
      revision = "7";
      sha256 = "9Ur7MVUuD4CQML7K00nL/hmmV1OneHcdxzFLKmxB5us=";
    };
    ## Earlier revisions are too restrictive on `base`.
    hie-compat = final.haskell.lib.overrideCabal hprev.hie-compat {
      editedCabalFile = "dKhYWpDjwGZnE0k5zRcM/yQGfVqYjhSCl4WvDfpr0Q8=";
      revision = "1";
      sha256 = "FWhmEEEOQePe2SpFICK03C8JSFg/HgJg36NhID4QBVQ=";
    };
    ## Earlier versions are too restrictive on `base` & `containers`.
    indexed-traversable = hfinal.indexed-traversable_0_1_4;
    ## Earlier versions are too restrictive on `base`.
    indexed-traversable-instances =
      final.haskell.lib.overrideCabal
      hprev.indexed-traversable-instances {
        editedCabalFile = null;
        sha256 = "PCu2L7oUHWaWF3Bw1juIvFaxlLxg9rc9ImOwJE4vx8E=";
        version = "0.1.2";
      };
    ## Earlier versions are too restrictive on `template-haskell`.
    lens = final.haskell.lib.overrideCabal hprev.lens {
      editedCabalFile = "idtM1SHdX8+taKDMjgAiFrkl8z92YACWiWhDM6zW3nA=";
      revision = "1";
      sha256 = "rCvzV0tzK3Tq5W0f2a+uaSt/HFmFMgrOJfGmrVwbccw=";
      version = "5.3";
    };
    ## `Control.Monad.Trans.List` is gone as of GHC 9.8, but
    ## `lifted-base` hasn’t updated its tests to avoid it.
    lifted-base = final.haskell.lib.dontCheck hprev.lifted-base;
    ## There is no release that supports base 4.20 yet.
    lucid = final.haskell.lib.doJailbreak hprev.lucid;
    ## Earlier revisions are too restrictive on `base`.
    nothunks = final.haskell.lib.overrideCabal hprev.nothunks {
      editedCabalFile = "JDJOr7UEoAvZwDSFUEFkGfsPoFXStypqzx6b5eCZhBE=";
      revision = "1";
      sha256 = "nHwKOFIRxdFCfbFWiWpW/AWwN01XXEKaHHoJ88ojveg=";
    };
    ## This version is too restrictive on `base`, but later versions
    ## lead to infinite recursion.
    # primitive = final.haskell.lib.doJailbreak hprev.primitive;
    ## Earlier versions are too restrictive on `base`.
    primitive = final.haskell.lib.overrideCabal hprev.primitive {
      editedCabalFile = "LgjFQJ41WcfxZp71DpoNmjl+aOz1ERDV4s7fBc3X2Tw=";
      revision = "1";
      sha256 = "aW1L0pHJTXNhQtYYIRfcpCWNPvKL/v22SayLXs0Jmcc=";
      version = "0.9.0.0";
    };
    ## Earlier versions are too restrictive on `base` & `containers`.
    quickcheck-instances =
      final.haskell.lib.overrideCabal
      hprev.quickcheck-instances {
        editedCabalFile = null;
        sha256 = "mxh+Gvk1Hf3CF+oCdDOtGd5oajZl4oznlwMixp2BTi8=";
        version = "0.3.31";
      };
    ## Earlier versions are too restrictive on `base`, `containers`, &
    ## `template-haskell`.
    scientific = final.haskell.lib.overrideCabal hprev.scientific {
      editedCabalFile = null;
      sha256 = "E7NDvKiqJtdxjlLmIuWhGAVmU+2vy8fMxTM75yFyGM8=";
      version = "0.3.8.0";
    };
    ## Earlier versions are too restrictive on `containers` &
    ## `template-haskell`.
    th-abstraction =
      final.haskell.lib.overrideCabal
      hprev.th-abstraction {
        editedCabalFile = "MTdg1jCFGg66a9yxoetUPEycWDBy1wQGf6MkilJSqK4=";
        revision = "2";
        sha256 = "aepuyh8MALbh4fgynJCOx25zhV4s5ukazi+Lv5LFGjA=";
        version = "0.6.0.0";
      };
    ## Earlier versions are too restrictive on `base`.
    these = final.haskell.lib.overrideCabal hprev.these {
      editedCabalFile = null;
      sha256 = "F9bZMzZe2r+AGhaELBQDvdN8xTAPqi/MqYDezasi5N4=";
      version = "1.2.1";
    };
    ## Earlier versions are too restrictive on `base`, and tests
    ## depend on a too-old version of `tasty`.
    time-compat = final.haskell.lib.overrideCabal hprev.time-compat {
      doCheck = false;
      editedCabalFile = null;
      sha256 = "yY++oh0DbDJjrxht8FabhCXIetNTsCE1N5R0Pk5jHcw=";
      version = "1.9.7";
    };
    ## Earlier revisions are too restrictive on `base`.
    unliftio-core =
      final.haskell.lib.overrideCabal
      hprev.unliftio-core {
        editedCabalFile = "9qJzb4WLU5DZOE3KQ9PqTZbpyhchd5F5HKSVG6boByo=";
        revision = "4";
        sha256 = "mThMuo1W2dYbheOKMTqT6823i+ZWY2fwkw71gFl/4+M=";
      };
    ## Earlier versions are too restrictive on `template-haskell`.
    uuid-types = final.haskell.lib.overrideCabal hprev.uuid-types {
      editedCabalFile = null;
      sha256 = "fg3ZU0g9b9PKSbyu1rEfnjwnhyE0ebJYHgd0eDa4NX4=";
      version = "1.0.6";
    };
  }
  else {}
)
## TODO: Various packages fail their tests on i686-linux. Should probably fix
##       them at some point.
// (
  if final.system == "i686-linux"
  then {
    aeson = final.haskell.lib.dontCheck hprev.aeson;
    enummapset = final.haskell.lib.dontCheck hprev.enummapset;
    ## Tests run out of memory (at least on garnix)
    generic-arbitrary = final.haskell.lib.dontCheck hprev.generic-arbitrary;
    hackage-security = final.haskell.lib.dontCheck hprev.hackage-security;
    persistent = final.haskell.lib.dontCheck hprev.persistent;
    relude = final.haskell.lib.dontCheck hprev.relude;
    slist = final.haskell.lib.dontCheck hprev.slist;
    ## Stack smashing
    sqlite-simple = final.haskell.lib.dontCheck hprev.sqlite-simple;
    unordered-containers =
      final.haskell.lib.dontCheck hprev.unordered-containers;
    validity = final.haskell.lib.dontCheck hprev.validity;
  }
  else {}
)
