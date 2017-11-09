#!/usr/bin/env python

import json
import sys

with open('bench-config.json') as data_file:
    data = json.load(data_file)

with open("bench-template.gp", 'r') as file :
  filedata = file.read()

plot_string = "plot "

line_style = 1

for config in data["build-configs"]:
    plot_string += "  'MEASURE." + config[1] + ".dat' using 1:4 t '" + config[0] + "' with linespoints ls " + str(line_style) + ", \\\n"
    line_style += 1

plot_string = plot_string[:-4] + "\n"

filedata = filedata.replace("PLOT-INST", plot_string.replace("MEASURE", "inst"))
filedata = filedata.replace("PLOT-MEM", plot_string.replace("MEASURE", "mem"))

with open("bench.gp", 'w') as file:
  file.write(filedata)
