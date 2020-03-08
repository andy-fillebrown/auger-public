#!/bin/bash

source ./setup-build-dir.sh
source ./setup-emsdk.sh
source ./versions.sh

if [ ! -d "flac-$FLAC_VERSION" ]; then
    wget http://downloads.xiph.org/releases/flac/flac-$FLAC_VERSION.tar.xz
    echo "Expanding flac-$FLAC_VERSION.tar.xz ..."
    tar xf flac-$FLAC_VERSION.tar.xz
    rm flac-$FLAC_VERSION.tar.xz
    echo "Expanding flac-$FLAC_VERSION.tar.xz - done"
fi

# TODO: Figure out how to pass emcc arguments to the build.
echo "Building flac ..."
cd ./flac-$FLAC_VERSION
emconfigure ./configure --enable-static --disable-shared --prefix=$BUILD_DIR --libdir=$BUILD_DIR/lib --includedir=$BUILD_DIR/include --with-ogg-libraries=$BUILD_DIR/lib --with-ogg-includes=$BUILD_DIR/include --host=asmjs
emmake make install
cd ..
echo "Building flac - done"
