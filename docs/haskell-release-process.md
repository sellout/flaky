# Haskell release process

We use continuous deployment, so every PR triggers a new release on Hackage.

## creating the PR

### isolate breaking changes

If you can create a useful PR with a subset of the changes that are non-breaking, please do so. Then create a second breaking PR blocked by that first PR.

This also applies even if you can only make _some_ of the packages non-breaking.

Don’t lump documentation & testing improvements into a breaking change just because they seem too trivial to provide on their own – they’re useful to get into a non-breaking revision.

### don’t make any changes to the version information

- don’t update the package versions
- don’t update any CHANGELOG.md
- don’t change repository-internal dependency ranges

### format the PR title as a CHANGELOG entry

__TODO__: How does this work when there are multiple packages?

## release updates

In as far as the release is automated, the changes should be made in the merge commit of the above PR. This means that merges can’t occur in the GitHub UI, as they require richer changes to be made.

1. make changes in dependency order of packages (repository last);
2. always continue to the end of the graph, to avoid missing dependency-related changes;
3. update dependency ranges for any repository-local packages you depend on[^1];
4. bump the version in the Cabal file according to the severity of the change;
5. add a new entry to the CHANGELOG.md based on the PR message (and add a reference to the new repository tag that will be created after this);
6. merge the PR;
7. create the new repository tag; and
8. push everything (this should automatically trigger publication on Hackage).

[^1]: This is delicate, because the CI build matrix doesn’t do a good job of solving for other versions of local packages.


## Hackage info

Hackage allows you to optionally tag a release as “preferred” or ”deprecated”.

All new releases are marked “preferred”, and “preferred” releases are the releases we officially support (so at some point, “preferred” is removed from existing releases).

“Deprecated” is reserved for releases that have some problem – a security issue, ones that fail to build with their claimed dependency ranges, etc. We won’t mark a release as deprecated simply because it’s not currently supported.
