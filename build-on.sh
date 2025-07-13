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

# This script builds a tarball of the package on a single platform.
# Usage: build-on.sh PACKAGE CONFIGURE_OPTIONS MAKE

package="$1"
configure_options="$2"
make="$3"

set -x

case "$configure_options" in
  --host=riscv*) cross_compiling=true ;;
  *)             cross_compiling=false ;;
esac

# Unpack the tarball.
tarfile=`echo "$package"-*.tar.gz`
packagedir=`echo "$tarfile" | sed -e 's/\.tar\.gz$//'`
tar xfz "$tarfile"
cd "$packagedir" || exit 1

mkdir build
cd build

# Configure.
../configure --config-cache $configure_options > log1 2>&1; rc=$?; cat log1; test $rc = 0 || exit 1

# Build.
$make > log2 2>&1; rc=$?; cat log2; test $rc = 0 || exit 1

if ! $cross_compiling; then
  # Run the tests.
  JAVA_VERBOSE=1 $make check > log3 2>&1; rc=$?; cat log3
  case `uname -s` in
    CYGWIN*)
      echo "CYGWIN DEBUG:"
      echo 'pwd => '; pwd
      echo 'ls -l examples/java/simple => '; ls -l examples/java/simple
      echo 'type java => '; type java
      echo 'env | grep -i java | sort => '; env | grep -i java | sort
      echo 'cat javaexec.sh => '; cat javaexec.sh
      echo '(cd examples/java/simple && java Calc) => '; (cd examples/java/simple && java Calc)
      ;;
  esac
  test $rc = 0 || exit 1
fi

cd ..
