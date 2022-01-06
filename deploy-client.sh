#!/bin/bash
lxc-destroy -f -n $1
lxc-stop  -n $1

IPV6=$5
echo "lxc.net.0.type = veth
lxc.net.0.flags = up
lxc.net.0.link = ffs-clients
lxc.net.0.hwaddr = $3

lxc.net.1.type = veth
lxc.net.1.flags = up
lxc.net.1.link = $2
lxc.net.1.hwaddr = $4

#lxc.net.2.type = veth
#lxc.net.2.flags = up
#lxc.net.2.link = virbr0
#lxc.net.2.hwaddr = $6
" > config 
ROOT="/var/lib/lxc/$1/rootfs"

echo lxc-create -n $1 -f config  -B lvm --vgname vg0 -t debian -- -r bullseye
#lxc-create -n $1 -f config  -B lvm --vgname vg0 -t debian -- -r buster
lxc-create -n $1 -f config  -t debian -- -r bullseye
echo "
nameserver 8.8.8.8
" > $ROOT/etc/resolv.conf
chroot $ROOT apt-get update
chroot $ROOT apt-get -y upgrade
chroot $ROOT apt-get -y install iputils-ping mtr
#I="chroot $ROOT apt-get -q -y --no-install-recommends  install"
#$I httping vim mtr wget iputils-ping dnsutils cron bind9-host dhcpcd5 screen
chroot $ROOT mkdir /root/.ssh
cp /root/.ssh/id_rsa.pub $ROOT/root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDMKsEPb02P1+nNbt2+8OYgvFiY4rPNAfosbjD4DBUgS4b0N4hXe6AgvV7xFrardPJr7APbLVnNlIWRmSHcXNyFdYdFvg8Kp8OzF7iPqguqEwsZR8yvqa+45DCGzsnRcgCf0DIFgt2nXETcoypf5EUm8Q2fowV1gWLTxo5ih50zSHUi1Nxi/DpvlNJtz1q9gbbiwmb/3eMlIFtEjrAlOHlK/UbVE/NO7AF6XcT2TpehmyHZTmUejmKnVDQ1lkv/tkspymPVqqBsA3XAAqm95DeAzZ5OeQ3YtA+dsYBC0SgC+hP6ZfshmWp/5LBQsnxfUoiapvL5iwcGoCA6zTjweAFv root@gw01n03" >> $ROOT/root/.ssh/authorized_keys
#echo "
#log_facility=daemon
#pid_file=/var/run/nagios/nrpe.pid
#server_port=5666
#nrpe_user=nagios
#nrpe_group=nagios
##allowed_hosts=fd42::e1:e1ff:fe5d:f39
#dont_blame_nrpe=0
#allow_bash_command_substitution=0
#debug=0
#command_timeout=60
#connection_timeout=300
#command[check_ping]=/usr/lib/nagios/plugins/check_ping  -H 8.8.8.8 -w 3000.0,80% -c 5000.0,100% -p 5
#command[check_dns]=/usr/lib/nagios/plugins/check_dns  -H heise.de -w 1 -c 2
#command[check_http]=/usr/lib/nagios/plugins/check_http  -H www.google.de -w 1 -c 2
#include=/etc/nagios/nrpe_local.cfg
#include_dir=/etc/nagios/nrpe.d/
#" > $ROOT/etc/nagios/nrpe.cfg

echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual
iface eth0 inet6 static
    address $IPV6
    netmask 64
            
auto eth1
iface eth1 inet dhcp

auto eth2
iface eth2 inet manual
iface eth2 inet6 static
    address $7
    netmask 64
    up ip -6 route add 2001:4ba0:fff1:1:beef::1 dev eth2 || true
    down ip -6 route del 2001:4ba0:fff1:1:beef::1 dev eth2 || true
    up ip -6 route add 2001:4ba0:fff1:f8::/64  via 2001:4ba0:fff1:1:beef::1 || true
    down ip -6 route del 2001:4ba0:fff1:f8::/64  via 2001:4ba0:fff1:1:beef::1 || true
    #up ip -6 route add default via 2001:4ba0:fff1:1:beef::1 dev eth2 || true
    #down ip -6 route del default via 2001:4ba0:fff1:1:beef::1 dev eth2 || true


" > $ROOT/etc/network/interfaces


lxc-start -d -n $1
