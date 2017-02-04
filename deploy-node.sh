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

curl  -s http://firmware.freifunk-stuttgart.de/gluon/nightly/factory/gluon-ffs-x86-64.img.gz | gunzip  > /var/lib/libvirt/images/$NAME.img
virsh net-create networks/ffs-nodes
virsh net-create networks/$NETWORK
ifconfig $NETWORK:0 192.168.1.100
virt-install --name $NAME --ram 32 -f /var/lib/libvirt/images/$NAME.img,device=disk --noautoconsole --network network=$NETWORK,model=virtio,mac=$MAC --network network=ffs-nodes,model=virtio --import

sleep 30
#send "cat ~/.ssh/id_rsa.pub > /etc/dropbear/authorized_keys\n\r"
expect << EOF
spawn telnet 192.168.1.1
expect -re ".*#"
send "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEhG8fsFEngZfvPj5xxivQv7FoBN+8ONLC6Rf27VVJMY7vsXhZWlqnxdf8GWr9hpOeo5nPpb7g7KYO4m/DltdHk09FPtoELCBtttsIYZ0/6vTCSPMaQ22j/f8X6pVEhHXvhEujq1cCoOlQjs8SUr/FkMa8IgKy09kw2lDMCD7OLlLNP771OJ0BB4VboZl1B0IifBleZkyfw2hHEF3k/gYygfuVyz9UH/lGi23FJJvjKsn9yvwXuy/zK2RqilCjbvQ0iE/J6weULP8KLbtl3YrnAbVIxStxoajxNiaOK52v1E9HsvShBDJalUtU1gzTLZbKlcvW0vGVywaknrBt70hZ root@bender.selfhosted.de' > /etc/dropbear/authorized_keys\n\r"
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
$SSH uci commit fastd
#$SSH opkg update
#$SSH opkg install mtr
$SSH reboot
echo undoing: 
echo ifconfig $NETWORK:0 192.168.1.100
ifconfig $NETWORK:0 down


