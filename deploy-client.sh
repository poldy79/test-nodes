#!/bin/bash
NAME=$1
ID=$2
VMID=9$ID
MAC=$4
IPV6=$5
MAC2=$6
IPETH2=$7
TEMPLATE=/zp0/pve-templates/template/cache/debian-11-standard_11.0-1_amd64.tar.gz
pct stop $VMID
pct destroy $VMID
pct create $VMID $TEMPLATE --storage zp0 --net0 name=eth0,bridge=vmbr3,ip=dhcp,ip6=auto,tag=$ID,type=veth --net1 name=eth1,bridge=vmbr4,firewall=0,ip6=$IPV6/64,type=veth --memory 512 --hostname $NAME

