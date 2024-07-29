### This module tries to get a consistent set of Haskell packages that work
### everywhere.
###
### Tests should be disabled as tightly as possible, but we should try to use
### the same version of a package across all systems & compilers.
final: prev: hfinal: hprev:
## TODO: Various packages fail their tests on i686-linux. Should probably fix
##       them at some point.
if final.system == "i686-linux"
then {
  #     enummapset = final.haskell.lib.dontCheck hprev.enummapset;
  hackage-security = final.haskell.lib.dontCheck hprev.hackage-security;
  persistent = final.haskell.lib.dontCheck hprev.persistent;
  #     sqlite-simple = final.haskell.lib.dontCheck hprev.sqlite-simple;
  unordered-containers =
    final.haskell.lib.dontCheck
    hprev.unordered-containers;
  validity = final.haskell.lib.dontCheck hprev.validity;
}
else {}
