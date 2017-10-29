#!/usr/bin/env python

import json
import sys

with open('bench-config.json') as data_file:
    data = json.load(data_file)

for bench in data["benchmarks"]:
    print(bench[0] + " " + str(bench[1]))
