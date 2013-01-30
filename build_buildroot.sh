#!/usr/bin/env bash
DIR=$(pwd)
OUT=${DIR}/out_buildroot
BUILDROOT=${DIR}/buildroot-A10
cd ${BUILDROOT}
make O=${OUT} allwinner_defconfig
make O=${OUT} BUILDROOT_DL_DIR=${DIR}/dl
