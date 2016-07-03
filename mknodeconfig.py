#!/usr/bin/python
import json
import sys
import md5
import subprocess
import uuid
from string import Template

network_template = """<network>
    <name>${if_name}</name>
    <uuid>${if_uuid}</uuid>
    <bridge name='${if_name}' stp='on' delay='0'/>
</network>
"""

def getFastdKeys():
    output = subprocess.check_output(["/root/freifunk/test-nodes/fastd", "--generate-key"],stderr=subprocess.STDOUT)
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
    fp = open("networks/%s"%(instance["if_name"]),"wb")
    fp.write(config)
    fp.close()

def generatePeerFile(name,mac,public,segment):
    fp = open("peers/%s/peers/ffs-%s"%(segment,mac.replace(":","")),"wb")
    fp.write("#MAC: %s\n"%(mac))
    fp.write("#Hostname: %s\n"%(name))
    fp.write("key \"%s\";\n"%(public))
    fp.close()

gws = {}
ports ={}
ports["vpn00"] = "10037"
ports["vpn01"] = "10041"
ports["vpn02"] = "10042"
ports["vpn03"] = "10043"
ports["vpn04"] = "10044"


gws["gw01"] = [0,1,2,3,4]
gws["gw05n01"] = [0,1,2,3,4]
gws["gw05n02"] = [1,2]
gws["gw05n03"] = [3,4]
gws["gw07n00"] = [1,2,3,4]
gws["gw07n02"] = [1,2,3,4]
gws["gw08n00"] = [0,1,2,3,4]
gws["gw08n02"] = [1,2,3,4]
gws["gw09"] = [0]
gws["gw10"] = [0,1,2,3,4]

try:
    fp = open("node-config.json","rb")
    instances = json.load(fp)
    fp.close()
except:
    instances = {}

for s in [0,1,2,3,4]:
    for gw in gws:
        if s in gws[gw]:
            segment = ("%i"%(s)).zfill(2)
            name = "s%s%s"%(segment,gw)

            instance = {}
            if name in instances:
                instance = instances[name]

            instance["name"] = "ffs-PoldyTestKvm-%s"%(name)
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
fp = open("node-config.json","wb")
json.dump(instances,fp, indent=4)
fp.close()

for instance in instances:
    i = instances[instance]
    print "./deploy-node.sh  %s %s %s %s %s %s.freifunk-stuttgart.de %s"%(i["name"],i["if_name"],i["mac"],i["secret"],i["gw"],i["remote"],ports[i["segment"]])
