#!/bin/sh

# Copyright (C) 2024-2025 Free Software Foundation, Inc.
#
# This file is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# This script builds the package.
# Usage: build-tarball.sh PACKAGE
# Its output is a tarball: $package/$package-*.tar.gz

package="$1"

set -e

# Fetch sources (uses package 'git').
# No '--depth 1' here, because we need to run git-version-gen.
git clone https://git.savannah.gnu.org/git/"$package".git
(cd "$package" && git submodule update --init submodules/autoconf)
git clone --depth 1 "${gnulib_url}"
export GNULIB_SRCDIR=`pwd`/gnulib

# Apply patches.
(cd "$package" && patch -p1 < ../patches/0001-build-Don-t-hardcode-the-location-of-the-gnulib-dire.patch)
(cd "$package" && patch -p1 < ../patches/0001-build-Fix-make-dvi-failure.patch)
(cd "$package" && patch -p1 < ../patches/bison.help-windows.patch)
(cd "$package" && patch -p1 < ../patches/0001-build-Avoid-failure-of-the-Java-tests-in-Cygwin-base.patch)

cd "$package"
# Force use of the newest gnulib.
rm -f .gitmodules

# Fetch extra files and generate files (uses packages wget, python3, automake, autoconf, m4).
{ $GNULIB_SRCDIR/build-aux/git-version-gen .tarball-version | sed -e 's/modified//'; date --utc --iso-8601; } > .tarball-version.tmp
mv .tarball-version.tmp .tarball-version
./bootstrap --no-git --gnulib-srcdir="$GNULIB_SRCDIR"
patch -p1 < ../patches/ylwrap-mingw.patch

# Configure (uses package 'file').
./configure --config-cache CPPFLAGS="-Wall" > log1 2>&1; rc=$?; cat log1; test $rc = 0 || exit 1
# Build (uses packages make, gcc, ...).
make > log2 2>&1; rc=$?; cat log2; test $rc = 0 || exit 1
# Run the tests.
make check > log3 2>&1; rc=$?; cat log3; test $rc = 0 || exit 1
# Check that tarballs are correct.
make distcheck > log4 2>&1; rc=$?; cat log4; test $rc = 0 || exit 1
