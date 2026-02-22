# Contributing to Flaky Haskell projects

**NB**: Most guidelines & justifications are in the [general contributing documentation](../CONTRIBUTING.md), this is just the Haskell-specific parts, which should be considered an addendum.

## building

Especially if you are unfamiliar with the Haskell ecosystem, there is a Nix build (both with and without a flake). If you are unfamiliar with Nix, [Nix adjacent](...) can help you get things working in the shortest time and least effort possible.

### if you have `nix` installed

`nix build` will build and test the project fully.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.

### traditional build

This project is built with [Cabal](https://cabal.readthedocs.io/en/stable/index.html). Individual packages will work with older versions, but ./cabal.package requires Cabal 3.6+.

## development

### CI failures

There are a few jobs that may fail during CI and indicate specific changes that need to be made to your PR. If you run into any failures other than those that are listed here, they likely have remedies that are specific to your changes. If you need help replicating or resolving them, or think that they represent general patterns like the ones listed below, inform the maintainers. They can help you resolve them and decide if they should be called out with generic resolution processes.

#### CI / check-bounds (check if bounds have changed)

A failure in the “check if bounds have changed” step indicates that the bounds on direct dependencies have changed.

It currently means that the discovered bounds have been restricted, which is always a breaking change. Unfortunately, this is sometimes not due to anything in the PR, but it does indicate we’re no longer testing the versions we used to – the Cabal solver will sometimes start choosing different packages, depending on releases. Due to the behavior of the solver, the most likely ones to change are in the middle of the range. There are a few ways to address this problem:

1. Simply change the bounds as the output recommends, and make sure the PR bumps the major version number. If this change is already bumping the major version, this is probably the right choice to make.
2. Try to force Cabal to try the previous bounds. If you had manually changed the bounds because you needed some new feature, is it possible to conditionalize use of that feature so that we can also still use and test with older bounds?
3. Tell CI that you want to keep the bounds the same even though they’re not tested. You do this by adding the old bound to the `extraDependencyVersions` list in flake.nix. This should be done carefully, but one use case is where those bounds _are_ tested by the Nix builds, but not by GitHub.

#### CI / check-licenses (check if licenses have changed)

This means there has _possibly_ been some change in the licensing, but it’s not foolproof. This only captures the licensing for one particular Cabal solution, so other solutions may have different transitive dependencies or licenses.

If there is a new license type in the list, it could affect how consumers of this can use our library. If the new license isn’t compatible with the existing set, then that’s a breaking change. If a package has changed its license, then we can alternatively restrict that package to versions that only use the previous license. Since making a license more restrictive introduces incompatibilities, this should only happen when they bump their major version, but there is no guarantee. In that case, this should just prevent us from extending the bounds, which is fine. But if it requires restricting bounds at the minor or revision level, then that’s still a breaking change on our side. Ideally we wouldn’t have to restrict that, but just make sure the consumer is informed about the license change and how to avoid it, but I don’t know how to convey that yet.

If there is a new dependency that has appeared, that should already be reflected in a major version bump. However, not all libraries introduce a major version bump when they add a dependency, and supporting wider version ranges means we may pick up a new dependency without excluding solutions that don’t involve that dependency.

It’s tempting to think that moving a dependency from the transitive list to the direct list doesn’t involve a version bump, but that’s not necessarily true. First, the transitive dependency must exist on all possible dependency solutions for that to be true. Then, it’s also possible for a new revision of a library to _remove_ dependencies, which means they will no longer appear in the transitive graph, invalidating our previous assumption. For this reason, we shouldn’t treat a move from transitive to direct as any different from a new dependency.

#### check formatter

There is some unformatted code (or perhaps some lint that needs addressing). If you use Nix, running `nix fmt` should automatically fix most of the formatting, and at least report additional lint that needs addressing.

If you don’t use Nix, the CI log should contain some lines like

```
treefmt 0.6.1
[INFO ] #alejandra: 1 files processed in 43.00ms
[INFO ] #prettier: 7 files processed in 423.85ms
[INFO ] #ormolu: 39 files processed in 1.60s
[INFO ] #hlint: 39 files processed in 2.15s
0 files changed in 2s (found 66, matched 86, cache misses 86)
```

Those `INFO` lines indicate which formatters were run. Running those same ones individually should address the issues. You can also just indicate in your PR that you don’t use Nix, and a maintainer will happily fix the formatting for you.

This implies a revision bump in any package that has been reformatted, as well as a revision bump in the repository.

#### check project-manager-files

Some files committed to the repository don’t match the ones that would be generated by Project Manager. This can happen either because you modified some of the Nix project configuration and forgot to regenerate the files, or because you edited generated files directly rather than editing the Nix project configuration.

If you use Nix, running `project-manager switch` from a project `devShell` (or `nix run github:sellout/project-manager -- switch`) anywhere should fix this (although check to see if you lost intentional changes to generated files, and add them via the Nix project configuration instead).

If you don’t use Nix, you will need to mention that in your PR so that one of the maintainers can resolve this for you.

## formatting

There are three ways to format, in order of preference, depending on your development environment.

1. `project-manager fmt`
2. `nix fmt`
3. [Ormolu](https://github.com/tweag/ormolu#readme)

The first two require [Nix](https://nixos.org/), but have the benefit of formatting everything in the repo, not just Haskell code. And `project-manager fmt` is much faster than `nix fmt`, because it caches the derivation and thus can avoid Nix evaluation.

## versioning

Individual packages largely follow the [Haskell Package Versioning Policy](https://pvp.haskell.org/) (PVP), but are more strict in some ways.

Note that repos have distinct versions from the packages they contain. Repo versions always follow [SemVer](https://semver.org/). There are a few reasons for this.

1. a single repo may contain multiple independently-versioned packages;
2. when a repo is used directly (for example, via a Nix flake or as a source dependency) there are parts of it outside of any single package (like the flake.nix) that need to be versioned as well; and
3. many repo-publishing tools (for example [Flakestry](https://flakestry.dev/) and [FlakeHub](https://flakehub.com/)) impose SemVer semantics.

The package version (PVP) always has four components, `A.B.C.D`. The first three correspond to those required by PVP, while the fourth matches the “patch” component from [Semantic Versioning](https://semver.org/).

Here is a breakdown of some of the constraints:

### sensitivity to additions to the API

PVP recommends that clients follow [these import guidelines](https://wiki.haskell.org/Import_modules_properly) in order that they may be considered insensitive to additions to the API. However, this isn’t sufficient. We expect clients to follow these additional recommendations for API insensitivity

If you don’t follow these recommendations (in addition to the ones made by PVP), you should ensure your dependencies don’t allow a range of `C` values. That is, your dependencies should look like

```cabal
yaya >=1.2.3 && <1.2.4
```

rather than

```cabal
yaya >=1.2.3 && <1.3
```

#### use package-qualified imports everywhere

If your imports are [package-qualified](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/package_qualified_imports.html?highlight=packageimports#extension-PackageImports), then a dependency adding new modules can’t cause a conflict with modules you already import.

#### avoid orphans

Because of the transitivity of instances, orphans make you sensitive to your dependencies’ instances. If you have an orphan instance, you are sensitive to the APIs of the packages that define the class and the types of the instance.

One way to minimize this sensitivity is to have a separate package (or packages) dedicated to any orphans you have. Those packages can be sensitive to their dependencies’ APIs, while the primary package remains insensitive, relying on the tighter ranges of the orphan packages to constrain the solver.

### transitively breaking changes (increments `A`)

#### removing a type class instance

Type class instances are imported transitively, and thus changing them can impact packages that only have your package as a transitive dependency.

#### widening a dependency range with new major versions

This is a consequence of instances being transitively imported. A new major version of a dependency can remove instances, and that can break downstream clients that unwittingly depended on those instances.

A library _may_ declare that it always bumps the `A` component when it removes an instance (as this policy dictates). In that case, only `A` widenings need to induce `A` bumps. `B` widenings can be `D` bumps like other widenings, Alternatively, one may compare the APIs when widening a dependency range, and if no instances have been removed, make it a `D` bump.

### breaking changes (increments `B`)

#### restricting an existing dependency’s version range in any way

Consumers have to contend not only with our version bounds, but also with those of other libraries. It’s possible that some dependency overlapped in a very narrow way, and even just restricting a particular patch version of a dependency could make it impossible to find a dependency solution.

#### restricting the license in any way

Making a license more restrictive may prevent clients from being able to continue using the package.

#### adding a dependency

A new dependency may make it impossible to find a solution in the face of other packages dependency ranges.

### non-breaking changes (increments `C`)

#### adding a module

This is also what PVP recommends. However, unlike in PVP, this is because we recommend that package-qualified imports be used on all imports.

### other changes (increments `D`)

#### widening a dependency range for non-major versions

This is fairly uncommon, in the face of `^>=`-style ranges, but it can happen in a few situations.

#### deprecation

**NB**: This case is _weaker_ than PVP, which indicates that packages should bump their major version when adding `deprecation` pragmas.

We disagree with this because packages shouldn’t be _publishing_ with `-Werror`. The intent of deprecation is to indicate that some API _will_ change. To make that signal a major change itself defeats the purpose. You want people to start seeing that warning as soon as possible. The major change occurs when you actually remove the old API.

Yes, in development, `-Werror` is often (and should be) used. However, that just helps developers be aware of deprecations more immediately. They can always add `-Wwarn=deprecation` in some scope if they need to avoid updating it for the time being.
