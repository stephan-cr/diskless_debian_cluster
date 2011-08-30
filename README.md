# Diskless Debian Cluster Setup Scripts

are based on [Debian](http://www.debian.org) and the
[Debian Diskless Cluster Howto](http://gabeortiz.net/2009/debian-diskless-cluster-howto/).
The present scripts automate most of the steps described in that
Howto. The difference to the just mentioned setup is, that it mounts
the NFS root filesystem as read-only and puts
[Aufs](http://aufs.sourceforge.net/) (an overlay-filesystem) on top of
it.

I tested the resulting system in a 50 node cluster, where no problems
showed up. The only fundamental disadvantage of this solution is, that
the system image for worker nodes cannot be updated online. This is,
because "Aufs" does not expect that the underlying read-only file
system is updated. That means, that you have to shutdown all nodes in
the cluster, do the update and to boot them up again (there is no free
lunch, sorry).

*WARNING:* Currently, the project is not that mature, i.e. it fulfills
primarily my personal needs, but I would love to see it becoming more
general.

If you are interested in a more mature project, then have a look
[FAI](http://fai-project.org).

The following sections describe how to setup a diskless Debian cluster
system.

## Requirements for the master node

- packages assumed to be installed
    - debootstrap
    - tftpd-hpa
    - syslinux
    - nfs-kernel-server
    - nfs-common
    - rsyslog

- services which are assumed to be already present
    - DHCP server
    - TFTP server (tftpd-hpa)
    - NFS server (nfs-kernel-server nfs-common)
    - NIS server

## Requirements for the worker nodes

- the nodes must have PXE (Preboot Execution Environment) enabled and
  the boot order must be changed to PXE first

## Setup

The setup consists of two parts, the setup of a master node and the
setup to bootstrap an image used as a base for the worker nodes.

The instructions assume that you already have a working cluster
installation.

1. change in the base directory where the scripts reside

2. configure "config.sh"

3. run "prepare_master.sh"

4. run "prepare_nfsroot.sh"

### DHCP entries

For those who do not already have DHCP entries for each worker
node. The file to adapt is `/etc/dhcp/dhcpd.conf`. An entry for each
worker node (IP, Mac, hostname) looks like follows:

    subnet @NETWORK@ netmask @NETMASK@ {
        filename "pxelinux.0";
        next-server @TFTP_SERVER_IP@;
        option subnet-mask @NETMASK@;
        option broadcast-address @BROADCAST@;
        option routers @ROUTER@;
    }

    host @WORKER_HOSTNAME@ {
        hardware ethernet @WORKER_MAC_ADDRESS@;
        fixed-address @WORKER_IP_ADDRESS@;
        option host-name "@WORKER_HOSTNAME@";
    }

## Design Characteristics and Consequences

- diskless means here that the *base* system does not require any
  local disk space
- designed by following the
  [KISS principle](http://en.wikipedia.org/wiki/KISS_principle)
- tries to be as non-intrusive as possible, i.e. the goal is to
  integrate well in already existing cluster setups (e.g. it is
  assumed that an DHCP-server already exists)
- local disks (if available) can completely be used by user
  applications (e.g. to place data on the disk such you get maximum
  read/write performance)
- heavily changing directories (like /home) should reside in a
  separate (writable) medium (like NFS or local discs), otherwise RAM
  is filled up
- the common shared base system ensures that all cluster nodes have
  exactly the same configuration (except e.g. the hostname and
  IP-address, of course)
- the base system image *cannot be updated online*, "Aufs" does not
  expect that the underlying read-only filesystem changes (if you try
  that out, the system may continue to work, but it will definitely
  crash later on)
- the master is a *single point of failure*
- works only with Debian Squeeze right now

## Contribute

This project definitely does need more work and help. Patches and
ideas are very welcome.
