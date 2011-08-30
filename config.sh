#!/bin/sh
#
# Copyright (c) 2011, Stephan Creutz
# Distributed under the GPLv3 License
# See accompanying file LICENSE

set -e

# master configuration options

DEBIAN_MIRROR="http://ftp.de.debian.org/debian/"

## network address where the cluster resides
NETWORK="192.168.0.0"
## netmask for the previous network
NETMASK="255.255.255.0"

## TFTP directory, the kernel image and boot entries are located there
TFTP_ROOT="/var/lib/tftpboot"

# nfs root configuration options

## path where the image for the worker nodes should reside
NFSROOT="/opt/nfsroot_diskless"
## IP address of the master/head node of the cluster
MASTERNODE_IP="192.168.0.254"
## TODO is this really required
DEFAULT_NIS_DOMAIN="Diskless-Debian-Cluster"
## is a linux ethernet bridge required
BRIDGE="y"
