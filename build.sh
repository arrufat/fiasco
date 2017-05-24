#!/usr/bin/env bash

[ -d build ] && rm -rf build
meson build
ninja -C build
