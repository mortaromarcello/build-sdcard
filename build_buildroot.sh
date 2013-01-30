DIR=$(pwd)
OUT=${DIR}/out_buildroot
BUILDROOT=${DIR}/buildroot-allwinner
cd ${BUILDROOT}
make allwinner_defconfig
make O=${OUT} -C ${BUILDROOT} BUILDROOT_DL_DIR=${DIR}/dl

