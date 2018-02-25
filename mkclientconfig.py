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
    with open("node-config.json","rb") as fp:
        instances = json.load(fp)
except:
    instances = {}

with open("node-config.json","wb") as fp:
   json.dump(instances,fp, indent=4)

try:
    with open("client-config.json","rb") as fp:
        clients = json.load(fp)
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

with open("client-config.json","wb") as fp:
    json.dump(clients,fp, indent=4)


for client in clients:
    c = clients[client]
    print("./deploy-client.sh %s %s %s %s %s %s %s"%(client,c["net"],c["eth0"],c["eth1"],c["addr"],c["eth2"],c["addrV6"]))

