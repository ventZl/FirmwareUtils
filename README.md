FIRMWAREUTILS README
====================

FirmwareUtils is a CMake module, which somewhat simplifies creation of
cross-compiled software. CMake itself has rather good support for
cross-compilation using toolchain files, yet one may face troubles if the
project he is working on requires either to build multiple components using
fundamentally different settings and/or build multiple instances of same
codebase using different configuration.

FirmwareUtils offers minimalistic facility to group multiple subprojects having
fundamentally different settings, which would normally require use of multiple
standalone CMakeLists.txt in order to keep things clean. Main goal is to get
*all* of the software getting built by single `make all`.


