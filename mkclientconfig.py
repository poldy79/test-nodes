#!/usr/bin/python3
import json
import sys
import hashlib
import subprocess
import uuid
from string import Template

def getMacFromName(name):
    m = hashlib.md5(name.encode("utf-8"))
    mac = []
    mac.append("02")
    for i,j in zip(range(0,10,2),range(2,12,2)):
        mac.append(m.hexdigest()[i:j])
    return ":".join(mac)



try:
    with open("node-config.json","r") as fp:
        instances = json.load(fp)
except:
    print("Starting with empty instances")
    instances = {}

with open("node-config.json","w") as fp:
   json.dump(instances,fp, indent=4)

try:
    with open("client-config.json","r") as fp:
        clients = json.load(fp)
except:
    clients = {}


for instance in instances:
    i = instances[instance]
    clientName = i["name"].replace("PoldyTestKvm","client")
    clientName = f"ffs-client-{instance}"
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
    c["vlan"] = f'{c["net"][5:7]}{c["net"][8]}{c["net"][10]}'
    t = c["eth0"].replace(":","")
    i = c["net"][9:11]
    if i == "":
        i = "0"
    c["addr"] = "fd42::%s:%s:%s"%(c["net"][5:7],c["net"][7:9],i)
    c["addrV6"] = "2001:4ba0:fff1:f8:42:%s:%s:%s"%(c["net"][5:7],c["net"][7:9],i)
    clients[clientName] = c

with open("client-config.json","w") as fp:
    json.dump(clients,fp, indent=4)


for client in clients:
    c = clients[client]
    #print(c)
    try:
        print("./deploy-client.sh %s %s"%(client,c["vlan"]))
    except:
        pass
