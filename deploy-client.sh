#!/bin/bash
#lxc-destroy -f -n $1
lxc-stop  -n $1

IPV6=$5
echo "
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = ffs-clients
lxc.network.hwaddr = $3

lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = $2
lxc.network.hwaddr = $4
" > config 
ROOT="/var/lib/lxc/$1/rootfs"

lxc-create -n $1 -f config  -t debian -- -r jessie
echo "
nameserver 8.8.8.8
" > $ROOT/etc/resolv.conf
chroot $ROOT apt-get update
I="chroot $ROOT apt-get -q -y --no-install-recommends  install"
$I httping vim mtr wget iputils-ping nagios-nrpe-server monitoring-plugins-basic bind9-host nagios-plugins-standard monitoring-plugins-standard dnsutils cron bind9-host
chroot $ROOT chmod u+s /bin/ping
chroot $ROOT mkdir /root/.ssh
cp /root/.ssh/id_rsa.pub $ROOT/root/.ssh/authorized_keys
echo "
log_facility=daemon
pid_file=/var/run/nagios/nrpe.pid
server_port=5666
nrpe_user=nagios
nrpe_group=nagios
#allowed_hosts=fd42::e1:e1ff:fe5d:f39
dont_blame_nrpe=0
allow_bash_command_substitution=0
debug=0
command_timeout=60
connection_timeout=300
command[check_ping]=/usr/lib/nagios/plugins/check_ping  -H 8.8.8.8 -w 3000.0,80% -c 5000.0,100% -p 5
command[check_dns]=/usr/lib/nagios/plugins/check_dns  -H heise.de -w 1 -c 2
command[check_http]=/usr/lib/nagios/plugins/check_http  -H www.google.de -w 1 -c 2
include=/etc/nagios/nrpe_local.cfg
include_dir=/etc/nagios/nrpe.d/
" > $ROOT/etc/nagios/nrpe.cfg

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
" > $ROOT/etc/network/interfaces


lxc-start -d -n $1
