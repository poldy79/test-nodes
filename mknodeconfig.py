#!/usr/bin/python
import json
import sys
import md5
import subprocess
import uuid
import os
from string import Template
import sys

network_template = """<network>
    <name>${if_name}</name>
    <uuid>${if_uuid}</uuid>
    <bridge name='${if_name}' stp='on' delay='0'/>
</network>
"""

def getFastdKeys():
    print("Generating fastd key...")
    output = subprocess.check_output(["/usr/bin/fastd", "--generate-key"],stderr=subprocess.STDOUT)
    lines = output.split("\n")
    public = lines[2].split(" ")[1]
    secret = lines[1].split(" ")[1]
    return (secret,public)


def getMacFromName(name):
    m = md5.new()
    m.update(name)
    mac = []
    mac.append("02")
    for i,j in zip(range(0,10,2),range(2,12,2)):
        mac.append(m.hexdigest()[i:j])
    return ":".join(mac)

def generateNetworkConfig(instance):
    tpl = Template(network_template)
    config = tpl.substitute(if_name=instance["if_name"], if_uuid=instance["if_uuid"])
    if not os.path.isdir("networks"):
        os.mkdir("networks")
    with open("networks/%s"%(instance["if_name"]),"w") as fp:
        fp.write(config)

def generatePeerFile(name,mac,public,segment):
    if not os.path.isdir("peers-ffs"):
        print("peers-ffs does not exist, execute\ngit clone git@github.com:freifunk-stuttgart/peers-ffs.git")
        sys.exit(1)
    if not os.path.isdir("peers-ffs/%s"%(segment)):
        os.mkdir("peers-ffs/%s"%(segment))
        os.mkdir("peers-ffs/%s/peers"%(segment))

    with open("peers-ffs/%s/peers/ffs-%s"%(segment,mac.replace(":","")),"w") as fp:
        fp.write("#MAC: %s\n"%(mac))
        fp.write("#Hostname: %s\n"%(name))
        fp.write("#Segment: fix %s\n"%(segment.replace("vpn","")))
        fp.write("key \"%s\";\n"%(public))

def getPort(vpn):
    vpn = int(vpn[3:])
    return 10200+vpn

gws = {}

if not os.path.isfile("nodebasename.txt"):
    print("Create nodebasename.txt with a unique-identifier for your nodes")
    sys.exit(1)

with open("nodebasename.txt","r") as fp:
    nodebasename = fp.read().strip()

#gws["gw01"] = [0]
gws["gw01n01"] = [1,2,3,4,5,6,7,8]
gws["gw01n03"] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24]
gws["gw04n01"] = [1,2,3,4,5,6,7,8]
gws["gw05n01"] = [1,2,3,4]
gws["gw05n02"] = [1,2,3,4]
gws["gw05n03"] = [1,2,3,4]
gws["gw05n04"] = [1,2,3,4,5,6,7,8]
gws["gw08n00"] = [1,2,3,4]
gws["gw08n01"] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
gws["gw08n02"] = [1,2,3,4]
gws["gw08n04"] = [1,2,3,4]
gws["gw08n06"] = [1,2,3,4,5,6,7,8]

try:
    with open("node-config.json","rb") as fp:
        instances = json.load(fp)
except:
    instances = {}

SEGMENTS=24

for s in range(0,SEGMENTS+1):
    for gw in gws:
        if s in gws[gw]:
            segment = ("%i"%(s)).zfill(2)
            name = "s%s%s"%(segment,gw)

            instance = {}
            if name in instances:
                instance = instances[name]

            instance["name"] = "ffs-%s-%s"%(nodebasename,name)
            instance["mac"] = getMacFromName(instance["name"])
            if not ("public" in instance and "secret" in instance): 
                (instance["secret"],instance["public"]) = getFastdKeys()
            instance["if_uuid"] = str(uuid.uuid5(uuid.NAMESPACE_OID,name))
            instance["if_name"] = "ffs-c%s%s"%(segment,gw.replace("gw","").replace("n",""))
            instance["segment"] = "vpn%s"%(segment)
            instance["node_id"] = "ffs-%s"%(instance["mac"].replace(":",""))
            instance["gw"] = gw[0:4]
            instance["remote"] = gw
            instances[name] = instance
            generateNetworkConfig(instance)
            generatePeerFile(instance["name"],instance["mac"],instance["public"],instance["segment"])

with open("node-config.json","w") as fp:
    json.dump(instances,fp, indent=4)

try:
    with open("client-config.json","r") as fp:
        clients = json.load(fp)
except:
    clients = {}

for instance in instances:
    i = instances[instance]
    clientName = i["name"].replace(nodebasename,"client")
    #print(clientName)


for instance in instances:
    i = instances[instance]
    port = getPort(i["segment"])
    print("./deploy-node.sh  %s %s %s %s %s %s.gw.freifunk-stuttgart.de %s"%(i["name"],i["if_name"],i["mac"],i["secret"],i["gw"],i["remote"],port))
