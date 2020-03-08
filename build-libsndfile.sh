#!/bin/bash

source ./setup-build-dir.sh
source ./setup-emsdk.sh

if [ ! -d "libsndfile" ]; then
    git clone https://github.com/andy-fillebrown/auger-wasm-libsndfile.git -b amf+/auger-wasm+/master ./libsndfile
fi

# TODO: Figure out how to pass emcc arguments to the build.
echo "Building libsndfile ..."
cd ./libsndfile
emcmake cmake \
-DCMAKE_VERBOSE_MAKEFILE=1 \
-DBUILD_EXAMPLES=0 \
-DBUILD_PROGRAMS=0 \
-DBUILD_SHARED_LIBS=0 \
-DBUILD_TESTING=0 \
-DCMAKE_BUILD_TYPE=MinSizeRel \
-DENABLE_EXTERNAL_LIBS=1 \
-DENABLE_PACKAGE_CONFIG=0 \
-DOGG_INCLUDE_DIR=$BUILD_DIR/include \
-DOGG_LIBRARY=$BUILD_DIR/lib/libogg.a \
-DFLAC_INCLUDE_DIR=$BUILD_DIR/include \
-DFLAC_LIBRARY=$BUILD_DIR/lib/libFLAC.a \
-DCMAKE_INSTALL_PREFIX=$BUILD_DIR
emmake make install
cd ..
echo "Building libsndfile - done"
