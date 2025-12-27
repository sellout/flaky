### This module tries to get a consistent set of Haskell packages that work
### everywhere.
###
### Tests should be disabled as tightly as possible, but we should try to use
### the same version of a package across all systems & compilers.
final: prev: hfinal: hprev:
## TODO: Various packages fail their tests on i686-linux. Should probably fix
##       them at some point.
(
  if final.stdenv.hostPlatform.system == "i686-linux"
  then {
    aeson = final.haskell.lib.dontCheck hprev.aeson;
    base64 = final.haskell.lib.dontCheck hprev.base64;
    enummapset = final.haskell.lib.dontCheck hprev.enummapset;
    ## Tests run out of memory (at least on garnix)
    generic-arbitrary = final.haskell.lib.dontCheck hprev.generic-arbitrary;
    hackage-security = final.haskell.lib.dontCheck hprev.hackage-security;
    persistent = final.haskell.lib.dontCheck hprev.persistent;
    relude = final.haskell.lib.dontCheck hprev.relude;
    slist = final.haskell.lib.dontCheck hprev.slist;
    ## Stack smashing
    sqlite-simple = final.haskell.lib.dontCheck hprev.sqlite-simple;
    stan = final.haskell.lib.dontCheck hprev.stan;
    unordered-containers =
      final.haskell.lib.dontCheck hprev.unordered-containers;
    validity = final.haskell.lib.dontCheck hprev.validity;
  }
  else {}
)
