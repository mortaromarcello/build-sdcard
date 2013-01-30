#!/usr/bin/env bash
DIR=$(pwd)
cd ${DIR}/sunxi-tools
make
sed -e 's/screen0_output_type = [0-9]/screen0_output_type = 1/' -e 's/screen0_output_mode = [0-9]/screen0_output_mode = 0/' script.fex > scriptmod.fex
./fex2bin script.fex scriptmod.bin
if [ ! -d $DIR/output ]; then
	mkdir -p ${DIR}/output
fi
cp -vf $DIR/sunxi-tools/scriptmod.bin ${DIR}/output/script.bin
cd ${DIR}
