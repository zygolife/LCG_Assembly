#!/usr/bin/env python
import sys, os
indir = "."
if len(sys.argv) > 1:
    indir = sys.argv[1]

finalOut="iprscan.xml"

final_list = []
logfiles   = []

for file in os.listdir(indir):
    if file.endswith('.xml'):
        final_list.append(os.path.join(indir, file))
    elif file.endswith('.log'):
        logfiles.append(os.path.join(indir, file))

with open(finalOut, 'w') as output:
    output.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n')
    output.write(
        '<protein-matches xmlns="http://www.ebi.ac.uk/interpro/resources/schemas/interproscan5">\n')
    for x in final_list:
        with open(x, 'rU') as infile:
            lines = infile.readlines()
            for line in lines[1:-1]:
                output.write(line)
    output.write('</protein-matches>\n')
