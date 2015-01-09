#!/bin/bash

set -e

mkdir -p "$CONFIGURATION_TEMP_DIR"
cd "$CONFIGURATION_TEMP_DIR"

ln -fs "$SRCROOT/binutils-gdb/" "$PROJECT_TEMP_DIR"

case "$ACTION" in
  clean)
    if [ -e Makefile ]; then
      make clean;
      rm -rf ./*
    fi
# This uninstall presumes that BUILT_PRODUCTS_DIR is install location for
# binutils only!
    rm -rf "$BUILT_PRODUCTS_DIR/bin"
    rm -rf "$BUILT_PRODUCTS_DIR/include"
    rm -rf "$BUILT_PRODUCTS_DIR/m68k-elf"
    rm -rf "$BUILT_PRODUCTS_DIR/share"
    exit 0
    ;;
esac

if [ ! -e Makefile ]; then
  "$PROJECT_TEMP_DIR/binutils-gdb/configure" $@;
fi
make
make install
