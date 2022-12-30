#!/bin/bash
NAME=$1
ID=$2
VMID=9$ID
source `hostname`.conf
pct stop $VMID
pct destroy $VMID
pct create $VMID $CT_TEMPLATE --features nesting=1 --storage ${ZP} \
	--net0 name=eth0,bridge=${BR_CLIENT},ip=dhcp,ip6=auto,tag=$ID,type=veth \
	--memory 512 --hostname $NAME
pct start $VMID

