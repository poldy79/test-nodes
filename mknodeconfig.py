#!/usr/bin/python3
import json
import sys
import hashlib 
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
    output = subprocess.check_output(["/usr/bin/fastd", "--generate-key"],stderr=subprocess.STDOUT).decode("utf-8")
    lines = output.split("\n")
    public = lines[2].split(" ")[1]
    secret = lines[1].split(" ")[1]
    return (secret,public)


def getMacFromName(name):
    m = hashlib.md5(name.encode("utf-8"))
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


def getInstances():
    gws = {}
    if not os.path.isfile("nodebasename.txt"):
        print("Create nodebasename.txt with a unique-identifier for your nodes")
        sys.exit(1)

    with open("nodebasename.txt","r") as fp:
        nodebasename = fp.read().strip()

    all_segments = list(range(1,34)) # Seg 1-33
    gws["gw01n03"] = all_segments
    gws["gw04n03"] = all_segments
    gws["gw05n02"] = [8,25,26]
    gws["gw05n03"] = all_segments
    gws["gw09n03"] = all_segments

    try:
        with open("node-config.json","rb") as fp:
            instances = json.load(fp)
    except:
        instances = {}

    SEGMENTS=33

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
                instance["id"] = f"{segment}{gw.replace('gw0','').replace('n0','')}"
                if not ("public" in instance and "secret" in instance): 
                    (instance["secret"],instance["public"]) = getFastdKeys()
                instance["if_uuid"] = str(uuid.uuid5(uuid.NAMESPACE_OID,name))
                instance["if_name"] = "ffs-c%s%s"%(segment,gw.replace("gw","").replace("n",""))
                instance["segment"] = "vpn%s"%(segment)
                instance["node_id"] = "ffs-%s"%(instance["mac"].replace(":",""))
                instance["gw"] = gw[0:4]
                instance["remote"] = gw
                instance["port"] = getPort(instance["segment"])
                instances[name] = instance
                generateNetworkConfig(instance)
                generatePeerFile(instance["name"],instance["mac"],instance["public"],instance["segment"])

    with open("node-config.json","w") as fp:
        json.dump(instances,fp, indent=4, sort_keys=True)

    try:
        with open("client-config.json","r") as fp:
            clients = json.load(fp)
    except:
        clients = {}

    for instance in instances:
        i = instances[instance]
        clientName = i["name"].replace(nodebasename,"client")
        #print(clientName)
    return instances

def main():
    instances = getInstances()
    for instance in instances:
        i = instances[instance]
        #port = getPort(i["segment"])
        try:
            print("./deploy-node.sh  %s %s %s %s %s %s.gw.freifunk-stuttgart.de %s"%(i["name"],i["id"],i["mac"],i["secret"],i["gw"],i["remote"],i["port"]))
        except:
            pass

if __name__ == "__main__":
    main()
