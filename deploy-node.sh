#!/bin/bash
#Parameter:
#1: name: s00-gw01
#2: network ffs-c0000
#3: mac
#4: secret
NAME=$1
ID=$2
VMID=8$ID
NETWORK=vmbr$2
MAC=$3
SECRET=$4
GW=$5
REMOTE=$6
PORT=$7
echo Creating $1
qm stop $VMID
qm destroy 80113 --destroy-unreferenced-disks 1 --purge 1

URL=http://firmware.freifunk-stuttgart.de/gluon/archive/2.3%2B2021-05-26/images/factory/gluon-ffs-2.3%2B2021-05-26-g.ee284141-s.0ee017e-x86-64.img.gz
mkdir /zp0/vz-images/images/$VMID
DEST=/zp0/vz-images/images/$VMID/vm-$VMID-disk-0.raw
echo $URL
echo $DEST
curl  -s $URL | gunzip  > $DEST
#virt-install --name $NAME --ram 48 -f /var/lib/libvirt/images/$NAME.img,device=disk --noautoconsole --network network=$NETWORK,model=virtio,mac=$MAC --network network=default,model=virtio --os-variant linux --import
qm create $VMID --boot order=scsi0 --cores 1 --memory 64 --name $NAME --net0 virtio=$MAC,bridge=vmbr3,tag=$ID --net1 virtio,bridge=vmbr1 --ostype l26 --scsi0 images:$VMID/vm-$VMID-disk-0.raw,cache=writeback,size=1G --scsihw virtio-scsi-pci --serial0 socket --rng0 source=/dev/urandom
qm start $VMID

sleep 30

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
