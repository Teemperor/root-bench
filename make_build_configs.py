#!/usr/bin/env python

import json
import sys

with open('bench-config.json') as data_file:
    data = json.load(data_file)

with open("build_names", "w") as f:
   for config in data["build-configs"]:
       f.write(config[0] + "\n")
with open("build_ids", "w") as f:
   for config in data["build-configs"]:
       f.write(config[1] + "\n")
with open("build_flags", "w") as f:
   for config in data["build-configs"]:
       f.write(config[2] + "\n")
