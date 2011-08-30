#!/bin/sh
#
# Copyright (c) 2011, Stephan Creutz
# Distributed under the GPLv3 License
# See accompanying file LICENSE

set -e

. ./config.sh

echo "preparing TFTP ..."

cp /usr/lib/syslinux/pxelinux.0 ${TFTP_ROOT}
[ -d "$TFTP_ROOT/pxelinux.cfg" ] || mkdir ${TFTP_ROOT}/pxelinux.cfg

# prepare remote logging
## prepare server
sed -i '/$ModLoad imudp/s/^#//;/$UDPServerRun/s/^#//' /etc/rsyslog.conf

# extend NFS exports
ech "extending NFS exports ..."
sed -i -e "s/@NFSROOT@/$NFSROOT/" \
    -e "s/@NETWORK@/$NETWORK/" \
    -e "s/@NETMASK@/$NETMASK/" \
    etc/exports >> /etc/exports
