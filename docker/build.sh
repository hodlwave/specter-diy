#!/bin/bash

set -e

PROJECT_ROOT="$(dirname "$(readlink -e "$0")")/.."
DOCKER_DIR="$PROJECT_ROOT/docker"
CACHEDIR="$DOCKER_DIR/.cache"
BUILDDIR="$DOCKER_DIR/build"
DISTDIR="$DOCKER_DIR/dist"

# pinned versions
PYTHON_VERSION=3.7.6

rm -rf "$BUILDDIR"
mkdir -p "$CACHEDIR" "$BUILDDIR" "$DISTDIR"

VERSION=`git describe --tags --dirty --always`
SPECTER_DIY_BIN="$PROJECT_ROOT/specter-diy-$VERSION.bin"

. "$DOCKER_DIR"/build_tools_utils.sh

info "fetching submodules recursively."
cd "$PROJECT_ROOT"
git submodule update --init --recursive

info "downloading some dependencies."
download_if_not_exist "$CACHEDIR/Python-$PYTHON_VERSION.tar.xz" "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tar.xz"
verify_hash "$CACHEDIR/Python-$PYTHON_VERSION.tar.xz" "55a2cce72049f0794e9a11a84862e9039af9183603b78bc60d89539f82cf533f"

info "building python."
tar xf "$CACHEDIR/Python-$PYTHON_VERSION.tar.xz" -C "$BUILDDIR"
(
    cd "$BUILDDIR/Python-$PYTHON_VERSION"
    LC_ALL=C export BUILD_DATE=$(date -u -d "@$SOURCE_DATE_EPOCH" "+%b %d %Y")
    LC_ALL=C export BUILD_TIME=$(date -u -d "@$SOURCE_DATE_EPOCH" "+%H:%M:%S")
    # Patch taken from Ubuntu http://archive.ubuntu.com/ubuntu/pool/main/p/python3.7/python3.7_3.7.6-1.debian.tar.xz
    patch -p1 < "$DOCKER_DIR/patches/python-3.7-reproducible-buildinfo.diff"
    ./configure \
      --cache-file="$CACHEDIR/python.config.cache" \
      --prefix="$DOCKER_DIR/usr" \
      --enable-ipv6 \
      --enable-shared \
      -q
    make -j4 -s || fail "Could not build Python"
    make -s install > /dev/null || fail "Could not install Python"
    # When building in docker on macOS, python builds with .exe extension because the
    # case insensitive file system of macOS leaks into docker. This causes the build
    # to result in a different output on macOS compared to Linux. We simply patch
    # sysconfigdata to remove the extension.
    # Some more info: https://bugs.python.org/issue27631
    sed -i -e 's/\.exe//g' "$DOCKER_DIR"/usr/lib/python3.7/_sysconfigdata*
)

dir_python() {
  env \
    PYTHONNOUSERSITE=1 \
    LD_LIBRARY_PATH="$DOCKER_DIR/usr/lib:$DOCKER_DIR/usr/lib/x86_64-linux-gnu${LD_LIBRARY_PATH+:$LD_LIBRARY_PATH}" \
    "$DOCKER_DIR/usr/bin/python3.7" "$@"
}
export python='dir_python'
export python3='dir_python'


info "building mpy cross-compiler"
cd $PROJECT_ROOT/f469-disco/micropython/mpy-cross
make

info "building f469 board"
cd $PROJECT_ROOT/f469-disco/micropython/ports/stm32
make BOARD=STM32F469DISC USER_C_MODULES=$PROJECT_ROOT/f469-disco/usermods FROZEN_MANIFEST=$PROJECT_ROOT/manifest.py
arm-none-eabi-objcopy -O binary build-STM32F469DISC/firmware.elf SPECTER_DIY_BIN
