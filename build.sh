#!/bin/sh  -e

MKIMG_DIR="/home/rossio/factory/aports/scripts"
OUT_DIR="/home/rossio/factory/iso"
PROFILE="rossio"
ARCH="x86_64"

mkdir -p "$OUT_DIR"

cp -f /home/rossio/factory/mkimg.${PROFILE}.sh ${MKIMG_DIR}
cp -f /home/rossio/factory/genapkovl-${PROFILE}.sh ${MKIMG_DIR}

cd "$MKIMG_DIR"

chmod +x mkimg.${PROFILE}.sh
chmod +x genapkovl-${PROFILE}.sh


./mkimage.sh --outdir "$OUT_DIR" --arch "$ARCH" --repository https://dl-cdn.alpinelinux.org/alpine/v3.23/main --repository https://dl-cdn.alpinelinux.org/alpine/v3.23/community --profile "$PROFILE"
echo "ISO CONSTRUCTION COMPETE"
