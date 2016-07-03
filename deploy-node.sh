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
virsh destroy $NAME
virsh undefine $NAME

curl  -s http://gw01.freifunk-stuttgart.de/gluon/stable/factory/gluon-ffs-x86-kvm.img.gz | gunzip  > /var/lib/libvirt/images/$NAME.img

ifconfig $NETWORK:0 192.168.1.100
virt-install --name $NAME --ram 64 -f /var/lib/libvirt/images/$NAME.img,device=disk --noautoconsole --network network=$NETWORK,model=virtio,mac=$MAC --network network=ffs-nodes,model=virtio --import

sleep 30
expect << EOF
spawn telnet 192.168.1.1
expect -re ".*#"
send "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCctEEoswagqM1FrjskrLXlJzXpJLthWBcowg2mWbyugl/Wlszq/hVFQd+5vRx6sVD1CTb0xPox0IO41ErG+97klw1tkhq2Bt8P0RfCSaJE9GcQHg6ylkAMzf9ZuFQjSOIUDA1EB0Tk6axFWL0AahfTCMljCdqejzyJX10+c158J0bSINR4mv5A2H6DYp0DsBJr6a82mEjEr+rHf8JjtdM/qwvKSgxikKm2e4fN0f8HQwMsjApLzqDjSMSi7CDiZpFeH4P56TABVAA7QFTZQiicSLXP0iZcXqWrvtHV5/Zb/3erjH8EQ+j9EGTncib9MPKbxzbdZmxmg1FW16NsDeDb root@sm' > /etc/dropbear/authorized_keys\n\r"
expect -re ".*#"
send "/etc/init.d/dropbear restart\n\r"
expect -re ".*#"
EOF
#send "reboot\n\r"
#sleep 30
sleep 3
SSH="ssh -q gluon-setup"
ssh gluon-setup uci set fastd.mesh_vpn.secret=$SECRET
ssh gluon-setup uci set gluon-setup-mode.@setup_mode[0].enabled='0'
ssh gluon-setup uci set gluon-setup-mode.@setup_mode[0].configured='1'
ssh gluon-setup uci commit gluon-setup-mode
echo ssh gluon-setup uci set system.@system[0].hostname=$NAME
ssh gluon-setup uci set system.@system[0].hostname=$NAME
ssh gluon-setup uci commit system
ssh gluon-setup /etc/init.d/system reload
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
$SSH uci commit fastd
$SSH reboot
echo undoing: 
echo ifconfig $NETWORK:0 192.168.1.100
ifconfig $NETWORK:0 down


