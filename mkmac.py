#!/usr/bin/python
import sys
import md5


def getMacFromName(name):
    m = md5.new()
    m.update(name)
    mac = []
    mac.append("02")
    for i,j in zip(range(0,10,2),range(2,12,2)):
        mac.append(m.hexdigest()[i:j])
    return ":".join(mac)


name = sys.argv[1]
print getMacFromName(name)


