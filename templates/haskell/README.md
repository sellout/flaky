# {{project.name}}

{{project.description}}

## building

## building & development

Especially if you are unfamiliar with the {{type.name}} ecosystem, there is a Nix build (both with and without a flake). If you are unfamiliar with Nix, [Nix adjacent](...) can help you get things working in the shortest time and least effort possible.

### if you have `nix` installed

`nix build` will build and test the project fully.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.

### traditional build

This project is built with [Cabal](https://cabal.readthedocs.io/en/stable/index.html). Individual packages will work with older versions, but ./cabal.package requires Cabal 3.6+.

## versioning

In the absolute, almost every change is a breaking change. This section describes how we mitigate that to provide minor updates and revisions.

Here are some of the common changes that can have unintended effects:

- adding instances can conflict with downstream orphans,
- adding a module can conflict with a module from another package,
- adding a definition to an existing module can conflict if there are unqualified imports, and
- even small bugfixes can introduce breaking changes where downstream depended on the broken results.

To mitigate some of those issues for versioning, we assume the following usage:

- modules should be imported using `PackageImports`, so that adding modules is a _minor_ change;
- modules should be imported qualified, so that adding definitions is a _minor_ change;
- adding instances can't be mitigated in the same way, and it's not uncommon for downstream libraries to add orphans instances when they're omitted from upstream libraries. However, since these conflicts can only happen via direct dependencies, and represent an explicit downstream workaround, it is reasonable to expect a quick downstream update to remove or conditionalize the workaround. So, this is considered a _minor major_ change;
- deprecation is considered a _revision_ change, however it will often be paired with _minor_ changes. `-Werror` can cause this to fail, but published libraries shouldn't be compiled with `-Werror`.

## comparisons

Other projects similar to this one, and how they differ.
