#!/bin/bash

source ./setup-build-dir.sh
source ./setup-emsdk.sh

if [ ! -d "csound" ]; then
    git clone https://github.com/andy-fillebrown/auger-wasm-csound.git -b amf+/auger-wasm+/master ./csound
fi

echo "Building csound ..."

cd ./csound
CSOUND_SOURCE_DIR=$PWD
cd ..

mkdir -p ./.build-csound
cd ./.build-csound

emcmake cmake \
-DCMAKE_VERBOSE_MAKEFILE=0 \
-DBUILD_PLUGINS_DIR="plugins" \
-DUSE_COMPILER_OPTIMIZATIONS=0 \
-DWASM=1 \
-DINIT_STATIC_MODULES=1 \
-DUSE_DOUBLE=NO \
-DBUILD_MULTI_CORE=0 \
-DBUILD_BUCHLA_OPCODES=0 \
-DBUILD_CHUA_OPCODES=0 \
-DBUILD_CUDA_OPCODES=0 \
-DBUILD_DSSI_OPCODES=0 \
-DBUILD_EMUGENS_OPCODES=0 \
-DBUILD_EXCITER_OPCODES=0 \
-DBUILD_FAUST_OPCODES=0 \
-DBUILD_FLUID_OPCODES=0 \
-DBUILD_FRAMEBUFFER_OPCODES=0 \
-DBUILD_HDF5_OPCODES=0 \
-DBUILD_IMAGE_OPCODES=0 \
-DBUILD_JACK_OPCODES=0 \
-DBUILD_LINEAR_ALGEBRA_OPCODES=0 \
-DBUILD_MP3OUT_OPCODE=0 \
-DBUILD_OPENCL_OPCODES=0 \
-DBUILD_OSC_OPCODES=0 \
-DBUILD_P5GLOVE_OPCODES=0 \
-DBUILD_PADSYNTH_OPCODES=0 \
-DBUILD_PLATEREV_OPCODES=0 \
-DBUILD_PVSGENDY_OPCODE=0 \
-DBUILD_PYTHON_OPCODES=0 \
-DBUILD_SCANSYN_OPCODES=0 \
-DBUILD_SELECT_OPCODE=0 \
-DBUILD_SERIAL_OPCODES=0 \
-DBUILD_STACK_OPCODES=0 \
-DBUILD_STK_OPCODES=0 \
-DBUILD_VST4CS_OPCODES=0 \
-DBUILD_WEBSOCKET_OPCODE=0 \
-DBUILD_WIIMOTE_OPCODES=0 \
-DEMSCRIPTEN=1 \
-DCMAKE_BUILD_TYPE=Release \
-G"Unix Makefiles" \
-DHAVE_BIG_ENDIAN=0 \
-DCMAKE_16BIT_TYPE="unsigned short" \
-DHAVE_STRTOD_L=0 \
-DBUILD_STATIC_LIBRARY=YES \
-DHAVE_ATOMIC_BUILTIN=0 \
-DHAVE_SPRINTF_L=NO \
-DUSE_GETTEXT=NO \
-DLIBSNDFILE_LIBRARY=$BUILD_DIR/lib/libsndfile.a \
-DSNDFILE_H_PATH=$BUILD_DIR/include \
$CSOUND_SOURCE_DIR

emmake make csound-static -j8 

emcc -Oz -g0 -s LINKABLE=1 -s ASSERTIONS=0 -DINIT_STATIC_MODULES=1 $CSOUND_SOURCE_DIR/Emscripten/src/FileList.c -Iinclude -o FileList.bc
emcc -Oz -g0 -s LINKABLE=1 -s ASSERTIONS=0 -DINIT_STATIC_MODULES=1 $CSOUND_SOURCE_DIR/Emscripten/src/CsoundObj.c -I$CSOUND_SOURCE_DIR/include -Iinclude -o CsoundObj.bc

# Total memory for a WebAssembly module must be a multiple of 64 KB so...
# 1024 * 64 = 65536 is 64 KB
# 65536 * 1024 * 4 is 268435456

# Keep exports in alphabetical order please, to correlate with CsoundObj.js.


## First build for WASM/ScriptProcessorNode (async compilation = 1, assertions = 0)
# emcc -v -Oz -g0 -DINIT_STATIC_MODULES=1 -s WASM=1 -s ASSERTIONS=0 -s "BINARYEN_METHOD='native-wasm'" -s LINKABLE=1 -s RESERVED_FUNCTION_POINTERS=1 -s TOTAL_MEMORY=268435456 -s ALLOW_MEMORY_GROWTH=1 -s NO_EXIT_RUNTIME=1 -s SINGLE_FILE=1 --pre-js $CSOUND_SOURCE_DIR/Emscripten/src/FileList.js -s BINARYEN_ASYNC_COMPILATION=1 -s MODULARIZE=1 -s EXPORT_NAME=\"'libcsound'\" -s EXTRA_EXPORTED_RUNTIME_METHODS='["FS", "ccall", "cwrap", "Pointer_stringify"]' CsoundObj.bc FileList.bc libcsound.a $BUILD_DIR/lib/libsndfile.a $BUILD_DIR/lib/libogg.a $BUILD_DIR/lib/libFLAC.a -o libcsound.js
 
## Second build for WASM/AudioWorklet (async compilation = 0, assertions = 0)
emcc -v -Oz -g0 -DINIT_STATIC_MODULES=1 -s WASM=1 -s ASSERTIONS=0 -s "BINARYEN_METHOD='native-wasm'" -s LINKABLE=1 -s RESERVED_FUNCTION_POINTERS=1 -s TOTAL_MEMORY=268435456 -s ALLOW_MEMORY_GROWTH=1 -s NO_EXIT_RUNTIME=1 -s SINGLE_FILE=1 --pre-js $CSOUND_SOURCE_DIR/Emscripten/src/FileList.js -s BINARYEN_ASYNC_COMPILATION=0 -s MODULARIZE=1 -s EXPORT_NAME=\"'libcsound'\"  -s EXTRA_EXPORTED_RUNTIME_METHODS='["FS", "ccall", "cwrap", "Pointer_stringify"]' CsoundObj.bc FileList.bc libcsound.a $BUILD_DIR/lib/libsndfile.a $BUILD_DIR/lib/libogg.a $BUILD_DIR/lib/libFLAC.a -o libcsound-worklet.js

# echo "AudioWorkletGlobalScope.libcsound = libcsound" >> libcsound.js

# --post-js does not work with MODULARIZE, use this for ES6 Module 
# echo "export default libcsound;" >> libcsound-worklet.js

cd ..
rm -rf .dist
mkdir .dist
cd .dist

cp $CSOUND_SOURCE_DIR/Emscripten/src/CsoundProcessor.js ./
cp $CSOUND_SOURCE_DIR/Emscripten/src/CsoundNode.js ./
# cp $CSOUND_SOURCE_DIR/Emscripten/src/CsoundScriptProcessorNode.js ./
cp $CSOUND_SOURCE_DIR/Emscripten/src/CsoundObj.js ./
cp $CSOUND_SOURCE_DIR/Emscripten/src/csound.js ./
# cp ../.build-csound/libcsound.js ./
cp ../.build-csound/libcsound-worklet.js ./

# TODO: Figure out why CsoundNode.js, CsoundProcessor.js and libcsound-worklet.js won't compile with Closure.
# TODO: Figure out if we can use `ADVANCED` Closure compile instead of default `SIMPLE`.
CLOSURE_COMPILER=../emsdk/upstream/emscripten/node_modules/google-closure-compiler-linux/compiler
$CLOSURE_COMPILER ./csound.js --js_output_file ./min/csound.js
# $CLOSURE_COMPILER ./CsoundNode.js --js_output_file ./CsoundNode.js
cp ./CsoundNode.js ./min
$CLOSURE_COMPILER ./CsoundObj.js --js_output_file ./min/CsoundObj.js
# $CLOSURE_COMPILER ./CsoundProcessor.js --js_output_file ./min/CsoundProcessor.js
cp ./CsoundProcessor.js ./min
# $CLOSURE_COMPILER ./CsoundScriptProcessorNode.js --js_output_file ./min/CsoundScriptProcessorNode.js
# $CLOSURE_COMPILER ./libcsound.js --js_output_file ./min/libcsound.js
# $CLOSURE_COMPILER ./libcsound-worklet.js --js_output_file ./libcsound-worklet.js
cp ./libcsound-worklet.js ./min

cd ..
echo "Building csound - done"
