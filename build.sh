#!/usr/bin/env sh
set -eu

OUT_DIR="build"
EXE_NAME="app"
SRC_DIR="src"

mkdir -p "$OUT_DIR"

if [ "${1:-}" = "release"]; then
  odin build "$SRC_DIR" -out:"$OUT_DIR/$EXE_NAME" -o:speed -vet -strict-style
else
  odin build "$SRC_DIR" -out:"$OUT_DIR/$EXE_NAME" -debug -vet -strict-style
fi
