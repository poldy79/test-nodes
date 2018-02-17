#!/usr/bin/python
import json
import sys
import md5
import subprocess
import uuid
from string import Template

def getMacFromName(name):
    m = md5.new()
    m.update(name)
    mac = []
    mac.append("02")
    for i,j in zip(range(0,10,2),range(2,12,2)):
        mac.append(m.hexdigest()[i:j])
    return ":".join(mac)



try:
    fp = open("node-config.json","rb")
    instances = json.load(fp)
    fp.close()
except:
    instances = {}

fp = open("node-config.json","wb")
json.dump(instances,fp, indent=4)
fp.close()

try:
    fp = open("client-config.json","rb")
    clients = json.load(fp)
    fp.close()
except:
    clients = {}

for instance in instances:
    i = instances[instance]
    clientName = i["name"].replace("PoldyTestKvm","client")
    if clientName in clients:
        c = clients[clientName]
    else:
        c = {}
    c["node"] = instance
    c["eth0"] = getMacFromName("%s%%%s"%(clientName,"eth0"))
    c["eth1"] = getMacFromName("%s%%%s"%(clientName,"eth1"))
    c["eth2"] = getMacFromName("%s%%%s"%(clientName,"eth2"))
    clients[clientName] = c
    c["net"] = i["if_name"]
    t = c["eth0"].replace(":","")
    i = c["net"][9:11]
    if i == "":
        i = "0"
    c["addr"] = "fd42::%s:%s:%s"%(c["net"][5:7],c["net"][7:9],i)
    c["addrV6"] = "2001:4ba0:fff1:f8:42:%s:%s:%s"%(c["net"][5:7],c["net"][7:9],i)

fp = open("client-config.json","wb")
json.dump(clients,fp, indent=4)
fp.close()


for client in clients:
    c = clients[client]
    print "./deploy-client.sh %s %s %s %s %s %s %s"%(client,c["net"],c["eth0"],c["eth1"],c["addr"],c["eth2"],c["addrV6"])

