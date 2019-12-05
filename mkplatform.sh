#!/bin/bash
C=`pwd`
A=../armbian
P=$1
V=v19.11

git clone https://github.com/armbian/build ${A}
cd ${A}
git checkout ${V} && touch .ignore_changes

cd ${C}
mkdir -p ${A}/userpatches/kernel/sunxi-dev
cp ${C}/patches/kernel/sunxi-dev/*.patch ${A}/userpatches/kernel/sunxi-dev/
#cp ${A}/config/kernel/linux-sunxi-current.config ${A}/userpatches/linux-sunxi-current.config
cd ${A}

#patch -p0 < ${C}/config.patch
./compile.sh KERNEL_ONLY=yes BOARD=${P} BRANCH=current LIB_TAG=${V} RELEASE=buster KERNEL_CONFIGURE=no EXTERNAL=yes BUILD_KSRC=no BUILD_DESKTOP=no

cd ${C}
rm -rf ${P}
mkdir ${P}
mkdir ${P}/u-boot
mkdir -p ${P}/usr/sbin

dpkg-deb -x ${A}/output/debs/linux-dtb-current-sunxi_* ${P}
dpkg-deb -x ${A}/output/debs/linux-image-current-sunxi_* ${P}
dpkg-deb -x ${A}/output/debs/linux-u-boot-current-${P}_* ${P}
dpkg-deb -x ${A}/output/debs/armbian-firmware_* ${P}
#mkdir ${P}/lib/firmware
#git clone https://github.com/armbian/firmware ${P}/lib/firmware
#rm -rf ${P}/lib/firmware/.git

cp ${P}/usr/lib/linux-u-boot-current-*/u-boot-sunxi-with-spl.bin ${P}/u-boot
#cp ${A}/packages/bsp/common/usr/sbin/armbian-add-overlay ${P}/usr/sbin

rm -rf ${P}/usr ${P}/etc

mv ${P}/boot/dtb* ${P}/boot/dtb
mv ${P}/boot/vmlinuz* ${P}/boot/zImage

mkdir ${P}/boot/overlay-user
#cp sun8i-h3-i2s0*.* ${P}/boot/overlay-user
dtc -@ -q -I dts -O dtb -o ${P}/boot/overlay-user/sun8i-h3-i2s0-master.dtbo ${C}/sources/overlays/sun8i-h3-i2s0-master.dts
dtc -@ -q -I dts -O dtb -o ${P}/boot/overlay-user/sun8i-h3-i2s0-slave.dtbo ${C}/sources/overlays/sun8i-h3-i2s0-slave.dts
dtc -@ -q -I dts -O dtb -o ${P}/boot/overlay-user/sun8i-h3-powen.dtbo ${C}/sources/overlays/sun8i-h3-powen.dts

cp ${A}/config/bootscripts/boot-sunxi.cmd ${P}/boot/boot.cmd
mkimage -c none -A arm -T script -d ${P}/boot/boot.cmd ${P}/boot/boot.scr
touch ${P}/boot/.next

echo "verbosity=1
logo=disabled
console=serial
disp_mode=1920x1080p60
overlay_prefix=sun8i-h3
overlays=i2c0
rootdev=/dev/mmcblk0p2
rootfstype=ext4
user_overlays=sun8i-h3-i2s0-slave
usbstoragequirks=0x2537:0x1066:u,0x2537:0x1068:u
extraargs=imgpart=/dev/mmcblk0p2 imgfile=/volumio_current.sqsh" >> ${P}/boot/armbianEnv.txt

case $1 in
'pc' | 'zero')
  sed -i "s/i2c0/i2c0 analog-codec/" ${P}/boot/armbianEnv.txt
  ;;
esac

tar cJf $P.tar.xz $P
