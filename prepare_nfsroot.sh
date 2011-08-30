#!/bin/sh
#
# Copyright (c) 2011, Stephan Creutz
# Distributed under the GPLv3 License
# See accompanying file LICENSE
#
# chroot in shell scripts:
#   http://www.infosecprojects.net/en/linuxtutorials/chroot.html

set -e

. ./config.sh

echo "bootstrapping debian image ..."
debootstrap --arch amd64 squeeze $NFSROOT $DEBIAN_MIRROR
# --include=<make a comma separated list out of file "packages">

cp packages $NFSROOT/
cp bin/whereami $NFSROOT/bin
cp etc/fstab etc/hosts $NFSROOT/etc
# configure fstab using a template
sed -i "s/@MASTERNODE_IP@/$MASTERNODE_IP/" $NFSROOT/etc/fstab
cp etc/network/interfaces $NFSROOT/etc/network/
# make the system as small as possible
echo '// disable installation of recommends
APT::Install-Recommends "0";' > $NFSROOT/etc/apt/apt.conf.d/90recommends
# don't call "debconf" while installing packages
sed -i '/^DPkg::Pre-Install-Pkgs/s/^/#/' $NFSROOT/etc/apt/apt.conf.d/70debconf

sed -n '/#######/,$p' $0 | sed -n '/bin\/sh/,$p' > $NFSROOT/$0

# execute everything below in a chroot environment
echo "executing script in chroot ..."
LC_ALL=C chroot $NFSROOT sh /$0
rm $NFSROOT/$0 $NFSROOT/packages

[ -e $NFSROOT/kernel_version ] || echo "kernel_version does not exist" > \
    /dev/stderr
KERNEL_VERSION=`cat $NFSROOT/kernel_version`
rm $NFSROOT/kernel_version

# pxelinux_cfg="
# LABEL linux
# KERNEL vmlinuz-${KERNEL_VERSION}
# APPEND root=/dev/nfs initrd=initrd.img-${KERNEL_VERSION} nfsroot=${MASTERNODE_IP}:${NFSROOT} ip=dhcp ro
# "

# "ipv6.disable=1" disables the following error message: "svc: failed to register lockdv1 RPC service"
pxelinux_cfg="
default linux

LABEL linux
KERNEL vmlinuz-${KERNEL_VERSION}
APPEND initrd=initrd.img-${KERNEL_VERSION} ip=dhcp boot=nfs nfsroot=${MASTERNODE_IP}:${NFSROOT} ro vga=795 fsprotect=auto ipv6.disable=1
"

echo "copying kernel and initrd image to TFTP directory..."
cp $NFSROOT/boot/vmlinuz-${KERNEL_VERSION} ${TFTP_ROOT}/
cp $NFSROOT/initrd.img-${KERNEL_VERSION} ${TFTP_ROOT}/
echo "$pxelinux_cfg" > ${NFSROOT}/pxe_cmd_line

# prepare nis client
echo "preparing NIS ..."
echo "$DEFAULT_NIS_DOMAIN" > $NFSROOT/etc/defaultdomain
echo "+::::::" >> $NFSROOT/etc/passwd
echo "+::::::::" >> $NFSROOT/etc/shadow
echo "+:::" >> $NFSROOT/etc/group
echo "+:::" >> $NFSROOT/etc/gshadow

# prepare remote logging
## prepare clients
echo "*.* @$MASTERNODE_IP:514" > $NFSROOT/etc/rsyslog.d/remote-logging.conf
## turn off local logging
sed -i '/#### RULES ####/,$d' $NFSROOT/etc/rsyslog.conf

exit

########## chroot environment starts here ##########
#!/bin/sh
# note: this script is executed inside a chroot environment

set -e

echo "[chroot script start]"

echo "mounting /dev/pts and /proc ..."
mount -t devpts none /dev/pts
mount -t proc none /proc

echo "installing packages ..."
aptitude --allow-untrusted -y install `sed '/^#/d' /packages`

# initramfs
echo "preparing initramfs ..."
sed -i '/^MODULES=/s/MODULES=.*/MODULES=netboot/;/^BOOT/s/BOOT=.*/BOOT=nfs/' \
    /etc/initramfs-tools/initramfs.conf

echo "aufs\nnetconsole" >> /etc/initramfs-tools/modules
if [ $BRIDGE = "y" ] ; then
    echo "bridge\nnetloop" >> /etc/initramfs-tools/modules
fi
KERNEL_VERSION=$(dpkg-query -W -f '${Depends}\n' linux-image-2.6-amd64 | \
    sed 's/linux-image-//')
echo $KERNEL_VERSION > /kernel_version
mkinitramfs -d /etc/initramfs-tools/ -o /initrd.img-${KERNEL_VERSION} \
    $KERNEL_VERSION

# setup to run multiple certain high frequently changing directories to tmpfs
sed -i '/^RAMRUN=/s/no/yes/;/^RAMLOCK=/s/no/yes/' /etc/default/rcS

# the "rcS" manpage says:
# "It is useful to disable this on machines with the root file system in NFS
#  until ifup from ifupdown work properly in such setup."
#
# in short it makes NFS mounts reliable
grep "^ASYNCMOUNTNFS" /etc/default/rcS > /dev/null
if [ $? = 0 ] ; then
    sed -i '/^ASYNCMOUNTNFS=/s/yes/no/' /etc/default/rcS
else
    echo "ASYNCMOUNTNFS=no" >> /etc/default/rcS
fi

echo "misc. other setup ..."
# unset hostname, use the one we got from the DHCP server
echo -n '' > /etc/hostname

# effectively disable blkid cache
ln -sf /dev/null /etc/blkid.tab

# use mtab from proc
ln -sf /proc/mounts /etc/mtab

aptitude clean
aptitude forget-new

umount /dev/pts
umount /proc

# set root password
passwd root

echo "[chroot script end]"
