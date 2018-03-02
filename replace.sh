#!/usr/bin/env bash
MOD_DIR="mods/workshop-1283844026"
DST_DIR="/mnt/c/Program Files (x86)/Steam/steamapps/common/Don't Starve Together"

if [ -z ${var+x} ]; then echo "DST_ROOT unset. Using default:" $DST_DIR; DST_ROOT=$DST_DIR; else echo DST_ROOT=$DST_ROOT; fi

rm -r "$DST_ROOT/$MOD_DIR/"
mkdir "$DST_ROOT/$MOD_DIR/"
cp -r "./src"/* "$DST_ROOT/$MOD_DIR/"