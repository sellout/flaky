## Invert warning state – Error on all warnings, disabling only
## backward-compatibility complaints.
## For Clang/C(++) specifically, the way to manage compatibility is to
## 1. enable the global settings
## 2. _disable_ `*-compat(-pedantic)?` flags for older compiler versions, then
## 3. explicitly enable the `*-compat(-pedantic)?` flags for current and future
##    versions.
## https://releases.llvm.org/16.0.0/tools/clang/docs/DiagnosticsReference.html
## More generally, see the “warnings” chapter of Beautiful Failures.
AM_CFLAGS = \
  -Werror -Weverything \
  -Wno-c99-compat
AM_CXXFLAGS = \
  -Werror -Weverything \
  -Wno-c++98-compat-pedantic -Wno-c++11-compat-pedantic \
  -Wno-c++14-compat-pedantic -Wno-c++17-compat-pedantic \
  -Wc++20-compat-pedantic
