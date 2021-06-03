#!/bin/bash
#Parameter:
#1: name: s00-gw01
#2: network ffs-c0000
#3: mac
#4: secret
NAME=$1
NETWORK=$2
MAC=$3
SECRET=$4
GW=$5
REMOTE=$6
PORT=$7
echo Creating $1
virsh destroy $NAME
virsh undefine $NAME
#URL=http://firmware.freifunk-stuttgart.de/gluon/archive/1.3/factory/gluon-ffs-x86-64.img.gz
#URL=http://firmware.freifunk-stuttgart.de/gluon/archive/1.9/factory/gluon-ffs-x86-64.img.gz
URL=http://firmware.freifunk-stuttgart.de/gluon/archive/2.3%2B2021-05-26/images/factory/gluon-ffs-2.3%2B2021-05-26-g.ee284141-s.0ee017e-x86-64.img.gz
curl  -s $URL | gunzip  > /var/lib/libvirt/images/$NAME.img
#truncate -s 1G /var/lib/libvirt/images/$NAME.img
#virsh net-create networks/ffs-nodes
virsh net-create networks/$NETWORK
virsh net-create networks/ffs-clients
#set -e 
ifconfig $NETWORK:0 192.168.1.100
echo virt-install --name $NAME --ram 48 -f /var/lib/libvirt/images/$NAME.img,device=disk --noautoconsole --network network=$NETWORK,model=virtio,mac=$MAC --network network=ffs-nodes,model=virtio --os-variant virtio26 --import
virt-install --name $NAME --ram 48 -f /var/lib/libvirt/images/$NAME.img,device=disk --noautoconsole --network network=$NETWORK,model=virtio,mac=$MAC --network network=default,model=virtio --os-variant linux --import

sleep 30
#send "cat ~/.ssh/id_rsa.pub > /etc/dropbear/authorized_keys\n\r"
expect << EOF
spawn telnet 192.168.1.1
expect -re ".*#"
send "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5jQU6UhGFfeQrEZ09cNjyFuOrOKZxslGGznblcr/SSjHGCtISk9Z4bGquMAuqcn4hd6xlT+SyRJaIivkAWFfzpUKFDtg4MyE47s82Ny0ZGHvP+I4BVQsjdwYFKZLK9iqmkqZ52YrgSSjbH1QKKHDqvYx97X2hZUDx96lNzQrZAxzr21UEIqxGTXjcrhCDy+g81gyHQLnPc/RgU28JKEtmm1yOWrlLyN5ylmmGrexyY2fo4asJIJ60+KWjbID7I0VDcCHV2g6GOkQBgBoY6VIX+3ipX3nN8ANdB24Vjf9906Vc+FQowQAFW/NxLRS6bS6LqwskTdkf2RHbPykuBrAl root@leela.selfhosted.de' > /etc/dropbear/authorized_keys\n\r"
expect -re ".*#"
send "/etc/init.d/dropbear restart\n\r"
expect -re ".*#"
send "exit\n\r"
EOF
#send "reboot\n\r"
#sleep 30
sleep 3
SSH="ssh -q -F ssh-config gluon-setup"
$SSH uci set fastd.mesh_vpn.secret=$SECRET
$SSH uci set gluon-setup-mode.@setup_mode[0].enabled='0'
$SSH uci set gluon-setup-mode.@setup_mode[0].configured='1'
$SSH uci commit gluon-setup-mode
$SSH uci set system.@system[0].hostname=$NAME
$SSH uci commit system
$SSH /etc/init.d/system reload
$SSH uci set fastd.mesh_vpn_backbone_peer_gw01.enabled='0'
$SSH uci set fastd.mesh_vpn_backbone_peer_gw02.enabled='0'
$SSH uci set fastd.mesh_vpn_backbone_peer_gw03.enabled='0'
$SSH uci set fastd.mesh_vpn_backbone_peer_gw04.enabled='0'
$SSH uci set fastd.mesh_vpn_backbone_peer_gw05.enabled='0'
$SSH uci set fastd.mesh_vpn_backbone_peer_gw06.enabled='0'
$SSH uci set fastd.mesh_vpn_backbone_peer_gw07.enabled='0'
$SSH uci set fastd.mesh_vpn_backbone_peer_gw08.enabled='0'
$SSH uci set fastd.mesh_vpn_backbone_peer_gw09.enabled='0'
$SSH uci set fastd.mesh_vpn_backbone_peer_gw10.enabled='0'
$SSH uci set fastd.mesh_vpn_backbone_peer_$GW.enabled='1'
$SSH uci set fastd.mesh_vpn_backbone_peer_$GW.remote=\'\"$REMOTE\" port $PORT\'
$SSH uci set fastd.mesh_vpn_backbone.auto_segment=0
$SSH uci commit fastd
#$SSH opkg update
#$SSH opkg install mtr
$SSH reboot
echo undoing: 
echo ifconfig $NETWORK:0 192.168.1.100
ifconfig $NETWORK:0 down


