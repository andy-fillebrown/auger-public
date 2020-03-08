#!/bin/bash

if [ ! -d "emsdk" ]; then
    git clone https://github.com/emscripten-core/emsdk.git

    cd ./emsdk
    ./emsdk install latest
    ./emsdk activate latest
    cd ..
    
    rm master.zip
fi

cd ./emsdk
source ./emsdk_env.sh
cd ..
