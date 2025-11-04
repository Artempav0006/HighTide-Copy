#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: YML_FILE=$1"
    exit 1
fi

YML_FILE="$1"
GEN_CORE_NAME="${DESIGN_NAME}_build"

echo "Setting up $DESIGN_NAME..."

cd "$LITEETH_DIR/dev"

source "$LITEETH_DIR/dev/.venv/bin/activate"

[ -d $LITEETH_DIR/dev/build ] && rm -rf build && echo "Cleaning previous build..."

python3 $LITEETH_DIR/dev/repo/liteeth/gen.py $YML_PATH/$YML_FILE && echo "Generating liteeth core..."

cp $LITEETH_DIR/dev/build/gateware/liteeth_core.v $LITEETH_DIR/dev/$DESIGN_NAME.v && echo "Copying verilog files..."

if [ ! -d $LITEETH_DIR/dev/$BUILD_DIR_NAME/$GEN_CORE_NAME ]; then
    mkdir $LITEETH_DIR/dev/$BUILD_DIR_NAME && mkdir $LITEETH_DIR/dev/$BUILD_DIR_NAME/$GEN_CORE_NAME
    cp -r $LITEETH_DIR/dev/build $LITEETH_DIR/dev/$BUILD_DIR_NAME/$GEN_CORE_NAME
else
    echo "Original build in $LITEETH_DIR/dev/$BUILD_DIR_NAME"
fi

[ -d $LITEETH_DIR/dev/build ] && rm -rf build