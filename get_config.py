#!/usr/bin/env python

import json
import sys

with open('bench-config.json') as data_file:
    data = json.load(data_file)

if sys.argv[1] in data:
    print(data[sys.argv[1]])
else:
    if len(sys.argv) > 2:
        print(sys.argv[2])
    else:
        exit(1)
