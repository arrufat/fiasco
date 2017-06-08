# Fiasco: Filter Images According to Size using Command-line Options

## Introduction

Fiasco is a small tool allowing to filter images inside directories that may contain errors.

All parameters can be personalised:

- The minimum NxN size allowed (default: 16)
- The output file (by default it prints on stdout)
- Whether to be recursive or not (default: OFF)
- Whether to perform faster, but less reliable checks (default: OFF)
- The number of threads to use to filter images out (default: ALL)
- Whether to be verbose or not (default: OFF)

When run without parameters, it will perform all available options with their default values.

If an option is specified incorrectly, it will suggest the most likely option.

## How to build

### Dependencies

Install the following dependencies on your system:

- glib2 (with development files)
- gdk-pixbuf2 (with development files)
- vala
- meson
- ninja

### Compilation

To compile run the following commands in the root directory

``` bash
meson build
ninja -C build
```

The binary should be in:
``` bash
./build/fiasco
```