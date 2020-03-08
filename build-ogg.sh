#!/bin/bash

source ./setup-build-dir.sh
source ./setup-emsdk.sh
source ./versions.sh

if [ ! -d "libogg-$OGG_VERSION" ]; then
  wget http://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.xz
  echo "Expanding libogg-$OGG_VERSION.tar.xz ..."
  tar xf libogg-$OGG_VERSION.tar.xz
  rm libogg-$OGG_VERSION.tar.xz
  echo "Expanding libogg-$OGG_VERSION.tar.xz - done"
fi

# TODO: Figure out how to pass emcc arguments to the build.
echo "Building libogg ..."
cd ./libogg-$OGG_VERSION
emconfigure ./configure --enable-static --disable-shared --prefix=$BUILD_DIR
emmake make install
cd ..
echo "Building libogg - done"
