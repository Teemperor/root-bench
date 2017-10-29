#!/usr/bin/env python

import sys

bench = sys.argv[1]
tutorial = sys.argv[2]

with open(bench, 'r') as file :
  filedata = file.read()
filedata = filedata.replace('TUTORIAL_NAME', tutorial)
with open(bench, 'w') as file:
  file.write(filedata)
