#!/bin/bash

set -ek
DESTDIR="$DSTROOT";
NCPUS=$(sysctl -n hw.ncpu)
export DESTDIR

# remove /usr/local/* from PATH because there might be some nonstandard stuff
# there that influences the build.
PATH=$(printf %s $PATH | sed -E 's/:\/usr\/local[^:]*(:|$)/\1/g')
echo $PATH

mkdir -p "$CONFIGURATION_TEMP_DIR"
mkdir -p "$CONFIGURATION_BUILD_DIR"
cd "$CONFIGURATION_TEMP_DIR"

ln -fs "$SRCROOT/binutils-gdb/" "$PROJECT_TEMP_DIR"

if [ "$ACTION" == "clean" ]; then
    if [ -e Makefile ]; then
      make clean;
      rm -rf ./*
    fi
# This uninstall presumes that BUILT_PRODUCTS_DIR is install location for
# binutils only!
    rm -rf "$CONFIGURATION_BUILD_DIR/bin"
    rm -rf "$CONFIGURATION_BUILD_DIR/include"
    rm -rf "$CONFIGURATION_BUILD_DIR/m68k-elf"
    rm -rf "$CONFIGURATION_BUILD_DIR/share"
    rm -f "$CONFIGURATION_BUILD_DIR/m68k-elf-ld"
    exit 0
fi

if [ ! -e Makefile ]; then
  "$PROJECT_TEMP_DIR/binutils-gdb/configure" $@;
fi
make -j $NCPUS "all-$TARGET_NAME"
if [ "$ACTION" == "install" ] && [ "$SKIP_INSTALL" == "NO" ]; then
  make "install-$TARGET_NAME"
fi
cp "$CONFIGURATION_TEMP_DIR/ld/ld-new" "$CONFIGURATION_BUILD_DIR/m68k-elf-ld"

if [ "$ACTION" == "install" ] && [ "$SKIP_INSTALL" == "YES" ]; then
  # I hope this doesn't break because it's not documented anywhere.
  UNINST_DIR="$TEMP_ROOT/UninstalledProducts/$PLATFORM_NAME"
  mkdir -p "$UNINST_DIR"
  cp "$CONFIGURATION_TEMP_DIR/ld/ld-new" "$UNINST_DIR/m68k-elf-ld";
fi
