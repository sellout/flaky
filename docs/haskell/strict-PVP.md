# Strict PVP (SPVP) v0.0.0.0

This is a versioning system that’s compatible with [the Haskell Package Versioning Policy](https://pvp.haskell.org/), but tries to prevent more issues with dependencies.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).

1. TOC
{:toc}

## terminology

- **bump**: this aligns with SemVer’s requirements, which are stricter than PVP here. “bumping” a component in a version means _incrementing_ that component while resetting all less-significant components to zero. (PVP doesn’t require resetting the less-significant components, but it’s certainly allowed and generally followed in practice.) **NB**: Because not all versions may be released, or may be unavailable for some reason, in practice it may appear as if the weaker requirements of PVP were followed (components increased instead of strictly incremented, and less significant components not reset).

- **change**: Some versioning documents talk about changing declarations, but any change to a type is an incompatible change, so we can see changes as simply a removal followed by an addition (with a conflicting name).

- **fine-grained API tracking**: This is a term I’m coining (maybe there’s prior art) for actually looking at the full transitive API of a module (roughly, the interface file, but with some additions), and analyzing each individual change. It allows you to have narrower version bumps than is implied by dependency versions. **FIXME**: This needs a specification too (for example, modified definitions aren’t apparent from an interface file, or, if they are, it’s not machine checkable whether they’re breaking changes – there should be a way to annotate these changes with how they affect the API, and if any annotations are missing, they can be inferred to be no more significant than the version bump)

## summary of differences from PVP (non-normative)

- requires PVP’s “insensitive to additions to the API” recommendations
- package-qualified imports must be used
- Strict PVP defines a “patch” level, corresponding to the `D` component (PVP references but never defines a “patch” level);
- removing any instance or adding an orphan instance requires an `A` bump instead of an increase in `A.B`;
- incompatible license changes require an `A` bump (PVP has nothing to say on licensing);
- adding a module moved from another package only **MAY** bump the major version (it’s “SHOULD” in PVP);
- deprecation only increments `D`, not `A.B` (compatible, because this is only a “SHOULD” in PVP);

## specification

A package that follows Strict PVP **SHOULD** declare that it does so (**FIXME**: We need a machine-checkable place to specify this declaration). This allows dependencies of the package to make additional assumptions based on the package version.

A package that follows Strict PVP **MAY** use fine-grained API tracking to use less significant version bumps than may be implied by simply looking at the source.

### fine-grained API tracking

Fine-grained API tracking uses tooling to produce more precise version numbers. For example, you may change a dependency from `^>= {2.0.0.0}` to `^>= {2.0.0.0, 3.0.0.0}`. This would normally require an `A` version bump in your next release. However, tooling can indicate that your exposed modules don’t leak any new instances due to the new dependency version, so you can release with only a `D` version bump.

**NB**: This may only be a deferral of the `A` bump. You may make a small bugfix change for your next release, and in doing so, add an import on a module in the dependency you previously widened. This new import may leak new instances, and trigger an `A` bump.

**NB**: Actually, any newly added import can trigger this kind of breakage … I’m beginning to think that Strict PVP can _only_ be done with this kind of tooling.

### version numbers

Version numbers serve multiple purposes

1. distinguishing different releases of the same package from each other (with only this requirement, the number could just as easily be a hash);
2. indicating a preference between those releases (higher version numbers are “better”); and
3. indicating similarities between releases, so that software developed against different releases can be distributed with a common release.

With this in mind, we want version numbers to communicate compatibility _conservatively_. If two releases share the same major components, we expect anything developed against the lower of the two will work when compiled against the newer of the two.

This largely follows the [Haskell Package Versioning Policy](https://pvp.haskell.org/) (PVP), but is more strict in some ways.

The package version always has four components, `A.B.C.D`[^1]. The first three correspond to those required by PVP, while the fourth matches the “patch” component from [Semantic Versioning](https://semver.org/).

[^1]: A mnemonic for the version components in strict PVP:
    - bumping `A` affects **A**ll dependencies,
    - bumping `B` **B**reaks something,
    - bumping `C` is a **C**ompatible change, and
    - bumping `D` only changes **D**ocumentation (and other non-behavioral things).

#### transitively breaking changes (bumps `A`)

There are “leaky” changes in most programming languages, where given a dependency graph like

```mermaid
graph LR
  bottom --> middle --> top
```

a change to `top` can break `bottom` (even if `middle` happens to be unaffected).

SemVer in general doesn’t offer a good way to manage this, but Haskell’s PVP (accidentally) does.

1. PVP (like SemVer) allows for more significant bumps than is required (for example, if you just add a bunch of documentation, which would normally be a revision, you’re allowed to release it as a new major version instead); and
2. PVP makes no distinction between bumping the `A` or `B` component of a version.

Given these constraints, we can require that making a transitively-leaking change requires bumping the `A` component. This works because of the first transitively-leaking change below:

#### breaking changes (bumps `B`)

#### non-breaking API changes (bumps `C`)

The difference between `C` and `D` changes can be a bit subtle. `C` is often seen as “additions” to the API, but it’s perhaps clearer to think of it as non-breaking changes to the API, whereas `D` doesn’t change the API at all.

#### other changes (bumps `D`)

### consumer requirements

These apply even if you’re not publishing a library that follows Strict PVP (for example, when you’re developing an application).

PVP recommends that clients follow [these import guidelines](https://wiki.haskell.org/Import_modules_properly) in order that they may be considered insensitive to additions to the API. However, this isn’t sufficient. Following Strict PVP implies insensitivity to additions to the API, and we strengthen the approach recommended by PVP with the following requirements.

#### use package-qualified imports everywhere

If your imports are [package-qualified](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/package_qualified_imports.html?highlight=packageimports#extension-PackageImports), then a dependency adding new modules can’t cause a conflict with modules you already import.

#### all non-package-local imports must be either qualified or have explicit import lists

**TODO**: Determine if `Prelude` really is [an exception to this rule](https://wiki.haskell.org/Import_modules_properly#Exception_from_the_rule) – is it true that `Prelude` is fixed going forward?

#### restriction of multiple imports with the same qualifier

If multiple imports use the same qualifier, all but one must all use explicit import lists. The remaining one may use either an explicit import list or a `hiding` clause containing a superset of the explicit imports of the other modules with the same qualifier.

### applied changes

Here is a description of which changes to the API require which changes to the version.

**FIXME**: Be clearer about “adding” and “removing”, etc. being about _the API_ – adding definitions that aren’t exported has no impact on the API.

Each of these cases is covered in the following sections with justifications, but this tries to give a quick rundown.

- “add” and “remove” refers to exports – internal changes generally don’t affect the interface (but be conscious of instances & term behavior)
- “changed” generally means the previous was “removed” and the new one was “added”, so use the more significant of the two columns
- a “persisting” type or class means that the type or class existed in a release prior to the addition, or continues to exist in the release containing the removal

|                                          | add         | remove  | syntax-only[^2] | note                                                                                                       |
|-----------------------------------------:|-------------|---------|-----------------|------------------------------------------------------------------------------------------------------------|
|                     [`import`](#imports) | `A`/`C`/`D` | `A`/`D` | ✔               | `C` when it’s part of a new module, `D` when there is persisting import for the same module                |
|                 [`instance`](#instances) | `A`/`C`     | `A`     |                 | only when applied to persisting types & classes, `C` when it’s part of a new module                        |
|                     [`module`](#modules) | `C`         | `A`/`B` | ✔               | `B` when the removed module had _zero_ imports                                                             |
|                                `-Werror` | `A`*        | `D`     |                 | **NB**: If you use `-Werror`, any change to the package is an `A` change                                   |
|                        `-fpackage-trust` | `A`         | `D`     |                 |                                                                                                            |
|             [constructor](#constructors) | `B`/`C`     | `B`     |                 | only when applied to persisting type, `C` when there were previously no exported constructors for the type |
|                                    field | `B`         | `B`     |                 | only when applied to persisting type                                                                       |
|                                   method | `B`/`C`     | `B`     |                 | `C` when added with unconstrained `default`                                                                |
|                               `COMPLETE` | `C`         | `B`     |                 |                                                                                                            |
|                                  `class` | `C`         | `B`     |                 | changing type parameter order counts as replacing class                                                    |
|                         method `default` | `C`         | `B`     |                 |                                                                                                            |
|                                `pattern` | `C`         | `B`     |                 | **NB**: changing is treated specially for patterns                                                         |
|                           [term](#terms) | `C`         | `B`     |                 | **NB**: changing is treated specially for terms                                                            |
| [type](#types) (`data`/`newtype`/`type`) | `C`         | `B`     |                 | changing type parameter order counts as replacing type                                                     |
|                                 comments | `D`         | `D`     |                 |                                                                                                            |
|              [dependency](#dependencies) | `D`         | `D`     |                 |                                                                                                            |
|      [`DEPRECATED`](#deprecated-pragmas) | `D`         | `D`     |                 |                                                                                                            |
|                                  Haddock | `D`         | `D`     |                 |                                                                                                            |

|                                    | tighten | weaken  | syntax-only[^2] | note                                                                                     |
|-----------------------------------:|---------|---------|-----------------|------------------------------------------------------------------------------------------|
|                            license | `A`     | `C`     |                 |                                                                                          |
|  [dependency bound](#dependencies) | `D`     | `A`/`D` | ✔               | `A` when new `A` or non-strict `B` version is supported, and for certain other libraries |
| [compiler bound](#compiler-bounds) | `B`/`D` | `D`     |                 | `D` when “guarded” by a corresponding non-reinstallable dependency tightening            |
|         [constraint](#constraints) | `B`     | `D`     |                 | **TODO**: type variable defaulting may be an issue here                                  |
|                        `type role` | `B`     | `D`     | ?               | “inferred” should be treated as between `representational` and `phantom`                 |
|                  Safe Haskell mode | `D`     | `B`     | ?               | “inferred” should be treated as between `Trustworthy` and `Unsafe`                       |

[^2]: “Syntax-only” means that this can be ignored (that is, it’s always a `D` change) when using fine-grained API versioning. If it’s a “?”, that means that “inferred” doesn’t apply for fine-grained API versioning, but otherwise the bumps stay the same.

#### `import`s

##### adding or removing an `import` (even to an internal module)

This only applies if there isn’t another import for the same module.

This one is very frustrating. Because adding or removing an import can change the set of instances that are exposed by the module that’s importing them. This also applies to non-`exposed` modules, because they’re imported by `exposed-modules`, and thus propagate those instances.

#### `instance`s

Conflicting instances only cause a problem at resolution time, not import time, so `middle` can inherit an orphan instance from `top` and another instance from elsewhere, but not exhibit a conflict because the instance is never used.

Orphans also make you [sensitive to some dependencies’ APIs](#avoid_orphans), but that only protects you from conflicts with non-orphan instances. The transitively-breaking restriction protects you from conflicts with orphans in other modules.

As described in [the PVP spec](https://pvp.haskell.org/#leaking-instances), removing instances can impact packages that only depend on your package transitively.

Type class instances are imported transitively, and thus changing them can impact packages that only have your package as a transitive dependency.

##### avoid orphans – **TODO**: This section is out of date

Because of the transitivity of instances, orphans make you sensitive to your dependencies’ instances. If you have an orphan instance, you are sensitive to the APIs of the packages that define the class and the types of the instance.

> _suggestion_: One way to minimize this sensitivity is to have a separate package (or packages) dedicated to any orphans you have. Those packages can be sensitive to their dependencies’ APIs, while the primary package remains insensitive, relying on the tighter ranges of the orphan packages to constrain the solver.

> _suggestion_: Cross-reference orphans in the Cabal package files. Collect the class names and relevant types for any orphans you define. Add a comment above the relevant dependencies in the Cabal package file listing which classes and types come from each.

**NB**: Alternatively, adding _any_ instance[^3] could be considered a transitively-breaking change. Then orphans wouldn’t need to trigger API sensitivity. On the one hand, that seems easier to manage and orphans are often unavoidable. However, it seems odd to penalize definers of non-orphan instances because of orphans, and relegating orphans to their own packages mitigates API sensitivity better than it mitigates transitively-breaking changes.

[^3]: Adding an instance at the same time as its class or a relevant type would always be a minor change, since there’s no way for an orphan to exist before that point.

#### `module`s

Like PVP we recommend a `C` bump when adding a module. However, unlike in PVP, this is because we recommend that package-qualified imports be used on all imports.

In the rare case that the module had _zero_ imports, removal is a `B` change (because this also implies that if there were any instances in the module, their types and classes were also self-contained and thus removed).

If there were imports, there may have been instances inherited, and those may now no longer be available to transitive consumers.

#### constructors

Because patterns are exported along with constructors, these must be invariant – any change is a breaking change. But you can export constructors if there were previously _no_ constructors available for the type, making it only a `C` change.

#### terms

##### changing the implementation of a term (sometimes)

This is the least-checkable case. If the implementation of a term changes between versions, the conservative option is to assume the behavior changed, which is a breaking change.

However, there are many refactorings, which don’t affect the behavior, but they aren’t easily checkable. The programmer needs to decide for each term whether the change affects the behavior or not. If it doesn’t it should only be a patch.

##### changing term & pattern definitions (including internal ones)

By default, _any_ change to a term or pattern definition (even an internal one) is considered an `A` change. This may sound severe, but a change in behavior can change the behavior of downstream referents, and cascade into their downstream consumers. **TODO**: Can we make this a `B` change by claiming that consumers are responsible for ensuring that they have sufficient testing to prevent changes in upstream behavior from slipping through their tests unnoticed?

For this reason, we recommend that any non-refactoring definition changes (that is, changes that affect behavior at all) be handled by removing the old identifier and adding a new one in its place. However, we understand that this isn’t always practical or ergonomic, so we make the following concessions.

This is the most subtle aspect of versioning. Let’s break it down into o few cases.

First, types are almost never truly incompatible (type parameters can allow wildly different types to be used in the same context). For this reason, we can’t rely on the type being different to ensure that changed behavior will be communicated sufficiently.

Now, if the change is a refactoring (🤞), that’s a `D` change.

If there’s an intentional change in behavior, that’s most safely a `A` change – even for internal definitions, because existing referents’ behavior may consequently change, and then the referents of those referents may change transitively. So, we strongly recommend you instead use a new term or pattern identifier, removing the old (making this a `B` change).

There are two ways to further restrict the version bump via auditing. They can be used independently or together.

1. Analyze _how_ the behavior changed
   – if it’s a clear bug (for example, correcting `decrement = (+ 1)` to `(- 1)` when `increment = (+ 1)` already exists, so no one is intentionally using the broken `decrement` to get around the functionality that isn’t available otherwise), then it’s a `D` change
   - if it improves handling of some cases (for example, it used to throw an exception in one case, but now handles it correctly), it’s a `D` change
   - if it re-categorizes things it’s an `A` change (because a consumer may have been relying on that particular grouping of results)

2. For an internal definition that has been determined to not be a `D` change, audit all its referents to see how _their_ behaviors have changed, at which point, you can ignore the internal definition’s change significance in favor of the audited definitions’ change significance. **NB**: this may add new internal functions to the set of changed definitions, so you can iterate on this step to ignore those.

#### types

##### changing types

As mentioned in the terminology, changes can be viewed as a removal (a breaking change) followed by an addition, so they’re understandably breaking changes. However, there are some subtle cases that are worth calling out.

###### changing the order of type parameters

This can happen due to syntactic changes that don’t otherwise affect the API (for example, changing the order of constraints on a function).

> _suggestion_: Enable [`ExplicitForAll`](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/explicit_forall.html#extension-ExplicitForAll) and add `forall` to any terms that have multiple type parameters, to insulate you from accidentally running into this.

#### dependencies

A new release won’t ever prevent the solver from succeeding with an old release, so while adding new dependencies or tightening bounds on existing dependencies might prevent the _new_ release from being solved for, it won’t break downstream consumers.

**TODO**: Add bit about which Cabal options to use to ensure that solving happens completely.

The one dependency-related change that’s more significant is, counterintuitively, widening the bounds. There are three cases where widening the bounds requires a bump to the `A` component:

1. adding a new `A` range for a dependency (for example, from `yaya ^>= {1.0.0}`, to `yaya ^>= {0.7.0, 1.0.0}`)
2. adding a new `B` range for a dependency that doesn’t claim to follow Strict PVP (for example, from `text ^>= {2.2.0}`, to `text ^>= {2.2.0, 2.3.0}`)
3. adding _any_ new support for a dependency that declares it doesn’t follow PVP (famously, [`ghc`](https://hackage.haskell.org/package/ghc)). These dependencies should use `==` instead of `^>=`.

This is what makes tracking transitively-breaking changes useful. If you follow this rule, then your consumers can’t be caught by these breakages, while still allowing you to avoid major version bumps for other breaking changes in your dependencies.

Unfortunately, PVP itself considers transitively-breaking changes to be simply breaking changes, and so unless a dependency declares itself as adhering to “strict PVP”, adding support for _any_ new breaking dependency versions is a transitively-breaking change.

**NB**: Some libraries (notably `ghc`) are known to not follow PVP. These shouldn’t use `^>=` ranges, and require more explicit versioning. Any change to these dependencies is an `A` bump.

#### licenses

If there is no explicit license, the default is “all rights reserved”, which is the most restrictive license possible. So, adding or removing a license is just a special case of weakening or tightening a license, respectively.

Making a license more restrictive may prevent clients from being able to continue using the package. The solver won’t take this into account, and transitive dependencies are responsible for the licensing of all their dependencies.

When weakening a license, you need to provide a way for consumers to say “I can only use it starting from this version” and that’s exactly what `C` bumps are for.

#### `DEPRECATED` pragmas

**NB**: This case is _weaker_ than PVP (but allowed by it).

PVP says that packages “SHOULD” bump their major version when adding `deprecated` pragmas.

We disagree with this because packages shouldn’t be _publishing_ with `-Werror`. The intent of deprecation is to indicate that some API _will_ change. To make that signal a major change itself defeats the purpose. You want people to start seeing that warning as soon as possible. The major change occurs when you actually remove the old API.

Yes, in development, `-Werror` is often (and should be) used. However, that just helps developers be aware of deprecations more immediately. They can always add `-Wwarn=deprecation` in some scope if they need to avoid updating it for the time being.

#### compiler bounds

Adding support for a compiler is a `D` bump.

##### removing support for a compiler version

The Cabal solver doesn’t look at compiler versions, so unlike with dependency bounds, we can’t make this a patch change. However, if there’s a corresponding tightening of a non-reinstallable dependency (like the `ghc` library), then the solver _does_ handle this for us, and it can be `D`.

**NB**: Even a minor restriction, like changing from supporting GHC 9.10.1(+) to 9.10.2(+) must be considered a breaking change, because some libraries included with GHC (like the `ghc` library) may have breaking changes even in a minor version bump. This means if a consumer has a dependency on the `ghc` library, it may be a breaking change for them to support 9.10.2.

#### constraints

##### weakening constraints

Haskell does type resolution independently of constraints. It then sees if the type that was resolved satisfies the constraints. So removing constraints doesn’t affect what type is resolved, therefore it can’t cause a resolution failure.

This is a good example of the difference between “additions to the API” and “non-breaking changes to the API”. This makes a function applicable in more situations, but doesn’t add anything to the API.

**FIXME**: I think this might not be true with [type variable defaulting](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/type_defaulting.html). For example, if you weaken a constraint from `RealFloat` to `Num`, and a consumer is using `default (Natural, Double)`, the switch from resolving `Double` to resolving `Natural` can then introduce a runtime failure when they call `negate`. There are mechanisms to disable defaulting, like  `default ()` or requiring `-Werror=type-defaults`, but those must be applied in the consumer, not the definer.

## incompatible extensions

### Secure PVP (SPVP is taken …)

This is incompatible with both PVP and SPVP. It requires that a security fix be no more significant than a minor change.

**TODO**: This section includes some things that are outside the scope of a versioning system, and should be listed as “_suggestion_”s.

A security fix **SHOULD** be made without breaking the API. However, if that’s not possible, the breaking change **MUST** bump `C` and leave `A` and `B` unchanged.

A security fix, even if breaking, **MUST** not include any other breaking changes. A security fix **SHOULD** not include any unrelated changes at all. Even trivial changes can impede analysis, and my have some subtle effect that undermines the release.

Whatever mechanisms are available **SHOULD** be used to deprecate[^4] the affected releases even before the fix is available. Once a fix is available, affected versions **SHOULD** be made unavailable.

[^4]: In this case, “deprecate” refers to something like the Hackage mechanism, where a deprecated release is only used if no other compatible release is available. This means that users will be downgraded where possible before a fix is even available.

This helps ensure that security fixes are propagated quickly, even if it means introducing breakages that need to be repaired.

**NB**: There’s what looks like a catch-22 here, but I think it’s an illusion – if a particular major version has an older unaffected release, then the actual fixed release may introduce an unnecessary breakage. But … if the older version wasn’t affected, then the fix must have been possible without breaking _that part_ of the API. That is, any breaking fix **SHOULD** only cause breakage to APIs that have already been deprecated.

#### be careful with dependency changes

While `C` and `D` changes won’t break anything downstream, you should be careful about changes that will prevent your new release from being solved for, because it’ll prevent users from getting your security fix.

The easiest way is to make _no_ dependency changes in a security change. Depending on consumer’s settings, even widening dependency resolution can result in an older version of your package being solved for (**TODO**: Find an example of this counterintuitive behavior). That said, often a security fix involves removing a vulnerable dependency, so it’s not always avoidable.
