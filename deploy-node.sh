#!/bin/bash
#Parameter:
#1: name: s00-gw01n03
#2: network ffs-c0000
#3: mac
#4: secret

NAME=$1
ID=$2
VMID=8$ID
MAC=$3
SECRET=$4
GW=$5
REMOTE=$6
PORT=$7

#BR_INTERNET=vmbr1
#BR_CLIENT=vmbr3
source `hostname`.conf

RAM=128
DISKSIZE=1G
VLAN=$ID
DELAY=30

echo Creating $1
qm stop $VMID
qm destroy $VMID --destroy-unreferenced-disks 1 --purge 1
BASE=http://firmware.freifunk-stuttgart.de/gluon/archive
HASHES=g.fffe05d3-s.9d037a1
VERSION=2.6%2B2022-11-08
FOLDER=${VERSION}-${HASHES}
RELEASE=${FOLDER}
URL=${BASE}/${FOLDER}/images/factory/gluon-ffs-${RELEASE}-x86-64.img.gz
DEST=/zp0/vz-images/images/$VMID/vm-$VMID-disk-0.raw
mkdir /zp0/vz-images/images/$VMID
echo URL: $URL
echo DEST: $DEST
curl  -s $URL | gunzip  > $DEST
qemu-img resize -f raw $DEST $DISKSIZE
qm create $VMID --boot order=scsi0 --cores 1 --memory $RAM --name $NAME \
	--net0 virtio=$MAC,bridge=${BR_CLIENT},tag=$VLAN \
	--net1 virtio,bridge=${BR_INTERNET} --ostype l26 \
	--scsi0 images:$VMID/vm-$VMID-disk-0.raw,cache=writeback,size=${DISKSIZE} \
	--scsihw virtio-scsi-pci --serial0 socket --rng0 source=/dev/urandom
qm start $VMID
echo -n Sleeping for $DELAY seconts...
sleep $DELAY
echo ok

expect << EOF
spawn qm terminal $VMID
expect -re ".*]"
send "\n\r"
expect -re ".*#"
send "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5jQU6UhGFfeQrEZ09cNjyFuOrOKZxslGGznblcr/SSjHGCtISk9Z4bGquMAuqcn4hd6xlT+SyRJaIivkAWFfzpUKFDtg4MyE47s82Ny0ZGHvP+I4BVQsjdwYFKZLK9iqmkqZ52YrgSSjbH1QKKHDqvYx97X2hZUDx96lNzQrZAxzr21UEIqxGTXjcrhCDy+g81gyHQLnPc/RgU28JKEtmm1yOWrlLyN5ylmmGrexyY2fo4asJIJ60+KWjbID7I0VDcCHV2g6GOkQBgBoY6VIX+3ipX3nN8ANdB24Vjf9906Vc+FQowQAFW/NxLRS6bS6LqwskTdkf2RHbPykuBrAl root@leela.selfhosted.de' > /etc/dropbear/authorized_keys\n\r"
expect -re ".*#"
send "/etc/init.d/dropbear restart\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn.secret=$SECRET\n\r"
expect -re ".*#"
send {uci set gluon-setup-mode.@setup_mode[0].enabled='0'}
send "\n\r"
expect -re ".*#"
send {uci set gluon-setup-mode.@setup_mode[0].configured='1'}
send "\n\r"
expect -re ".*#"
send "uci commit gluon-setup-mode\n\r"
expect -re ".*#"
send {uci set system.@system[0].hostname=$NAME}
send "\n\r"
expect -re ".*#"
send "uci commit system\n\r"
expect -re ".*#"
send "/etc/init.d/system reload\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_gw01.enabled='0'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_gw02.enabled='0'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_gw03.enabled='0'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_gw04.enabled='0'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_gw05.enabled='0'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_gw06.enabled='0'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_gw07.enabled='0'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_gw08.enabled='0'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_gw09.enabled='0'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_gw10.enabled='0'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_$GW.enabled='1'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone_peer_$GW.remote=\'\"$REMOTE\" port $PORT\'\n\r"
expect -re ".*#"
send "uci set fastd.mesh_vpn_backbone.auto_segment=0\n\r"
expect -re ".*#"
send "uci commit fastd\n\r"
expect -re ".*#"
send "reboot\n\r"
EOF

echo Node is rebooting
