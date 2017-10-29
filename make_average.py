#!/usr/bin/env python

import sys

in_file = sys.argv[1]
out_file = sys.argv[2]

with open(in_file) as f:
    content = f.readlines()
content = [x.strip() for x in content]

entries=[]
for line in content:
  entries.append(int(line))

avg = sum(entries) / float(len(entries))

with open(out_file, "w") as o:
    o.write(str(int(avg)))
