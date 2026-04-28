#!/usr/bin/env bash
#
# slsa-autotools bootstrap hook for htop.
#
# Runs in place of the default ./autogen.sh step in scan.yml and
# release.yml. Handles one fork-agnostic quirk:
#
#   htop's curses detection in configure.ac is a hand-rolled
#   "for n in $curses_pkg_names; do $PKG_CONFIG --exists $n; done"
#   loop, not the AM_PATH_/PKG_CHECK_MODULES macros the slsa-autotools
#   resolver scrapes. The resolver therefore does not auto-install
#   libncurses-dev, configure aborts with "cannot find required
#   curses/ncurses library", and the trace never starts.
#
#   Pre-installing libncurses-dev here lets configure succeed; the
#   ensuing strace captures the ncurses headers as ordinary file
#   opens and the path->package mapper pins libncurses-dev in the
#   emitted Dockerfile. Subsequent release runs against the pinned
#   image are no-ops on this install (the package is already there).
#
# Subsequent steps (configure, make dist) run from the calling
# workflow.

set -euo pipefail

if ! dpkg-query -W -f='${Status}' libncurses-dev 2>/dev/null | grep -q 'install ok installed'; then
  apt-get update -qq
  apt-get install -y --no-install-recommends libncurses-dev
fi

./autogen.sh
