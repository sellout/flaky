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

### coding

#### disabling checks

By default, there is a ton of automatically-checked coding style, etc. This isn’t meant to deter contributions. When making changes, feel free to weaken these checks as necessary, but please do so as narrowly as possible, and with comments justifying it.

Here are some of the checks and how to disable them

##### `NoRecursion`

Add a line to the top of the module that looks like

```haskell
{-# OPTIONS_GHC -fplugin-opt NoRecursion:ignore-decls:<list of terms that use recursion> #-}
```

##### GHC warnings

Add a line to the top of the module that looks like

```haskell
{-# OPTIONS_GHC -Wno-<warning name> #-}
```

### documenting

Documentation is very important, but it shouldn’t detract from good naming. That said, it’s extremely rare that a name can convey all the details required, so having documentation on at least all exported declarations is required (and enforced by [henforcer](https://github.com/flipstone/henforcer#readme)). It’s also required that all exported declarations have an [`@since` annotation](https://haskell-haddock.readthedocs.io/latest/markup.html#since). If the package hasn’t yet been released, `@since 0.0.1`[^1] is the correct annotation to use.

[^1]: You should never use a fourth component on an exposed module, because any change to the public exports is at least a minor change. Declarations in modules listed in `other-modules` may have a fourth component, because those exports are internal to the package.

Documentation is written using [Haddock](https://haskell-haddock.readthedocs.io/), and it’s helpful to add Doctest examples, as described in the “testing” section below.

__NB__: Haddock isn’t Markdown! But the similarities can make it easy to forget sometimes. Please try to review your doc changes using [`cabal haddock-project`](https://cabal.readthedocs.io/en/stable/cabal-commands.html#cabal-haddock-project) before submitting them.

#### guidelines

##### document parameters at the parameter level

For example, instead of

```haskell
-- | This function does something. The first argument indicates whether it
--   should be done correctly.
foo :: Bool -> Int -> Char
```

do

```haskell
-- | This function does something.
foo ::
  -- | Whether to do the thing correctly.
  Bool ->
  Int ->
  Char
```

##### don’t describe the internals in Haddock

Instead, use regular comments in the body of the function to call out implementation details. But using Haddock syntax in regular comments is encouraged.

### testing

It’s very helpful to add individual examples with [Doctest](https://github.com/sol/doctest#readme), which will appear in the generated [Haddock](https://haskell-haddock.readthedocs.io/) documentation (published on [Hackage](https://hackage.haskell.org/)). These are run as Cabal tests, to ensure they don’t get out of date.

However, the bulk of the testing should be covered with property tests.

There is a bit of a snag here. Generally, there’s a library or two that exposes helpers so that downstream consumers of the library can write tests more easily as well. This often means that most (if not all) tests can’t easily be written as a test suite on the core library. Consequently, we end up with a structure like

```cabal
name foo

library
```

``` cabal
name: foo-hedgehog

library
  build-depends:
    foo,
    hedgehog,

test-suite foo
  build-depends:
    foo,
    foo-hedgehog,
    hedgehog,
```

where [Hedgehog](https://github.com/hedgehogqa/haskell-hedgehog#readme) is a popular property-testing framework. `foo-hedgehog` contains generators and other definitions that are useful for testing `foo` with Hedgehog. So, most of the testing of `foo` is handled in a `foo-hedgehog` `test-suite`.[^2]

[^2]: There are other ways to separate the testing library from the core library. One is to add a `library hedgehog` stanza to the Cabal file for `foo`. However, then the `foo:hedgehog` sublibrary 1. can’t be versioned independently of the `foo` library and 2. there are still a number of tools that don’t support public sublibraries, so the more explicit separation is preferred. You could also fold the `foo-hedgehog` library into the `foo` library, but this isn’t great, because we don’t want to link test dependencies into the core library.

Sometimes there’s also (or instead) a `foo-quickcheck` package. This may also have a test suite, but is generally used for including property tests in Doctest, because [Doctest has built-in support for QuickCheck property testing](https://github.com/sol/doctest?tab=readme-ov-file#quickcheck-properties). If the repository you’re working on has a `foo-quickcheck`, but no `foo-hedgehog`, feel free to put property tests for the core library into a `foo-quickcheck` `test-suite`.

Sometimes there are non-property tests included, and these tend to be done with Tasty & [Hspec](https://hspec.github.io/). If they don’t rely on any particular helpers, the tests can be defined directly on the core package.

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

The first two require [Nix](https://nixos.org/), but have the benefit of formatting everything in the repository, not just Haskell code. And `project-manager fmt` is much faster than `nix fmt`, because it caches the derivation and thus can avoid Nix evaluation.

## versioning

Packages follow [Strict PVP](../haskell-strict-PVP.md), which is compatible with [PVP](https://pvp.haskell.org/), but provides additional guarantees. That is, if your package follows PVP, you can treat our versions the same as any other PVP version, but if your package follows Strict PVP itself, it can take advantage of the additional guarantees provided here.

Note that repositories have distinct versions from the packages they contain. Repository versions always follow [SemVer](https://semver.org/). There are a few reasons for this.

1. a single repository may contain multiple independently-versioned packages;
2. when a repository is used directly (for example, via a Nix flake or as a source dependency) there are parts of it outside of any single package (like the flake.nix) that need to be versioned as well; and
3. many repo-publishing tools (for example [Flakestry](https://flakestry.dev/) and [FlakeHub](https://flakehub.com/)) impose SemVer semantics.
