#!/usr/bin/env python
import csv, re

in1='lib/Mortierellaceae_BioProjects.csv'
in2='samples_prefix.csv'
out1="prefix_samples.templates.csv"

with open(in1,"rU") as i1, open(in2,"rU") as i2, open(out1,"w") as o1:
    r1 = csv.reader(i1)
    r2 = csv.reader(i2)
    out = csv.writer(o1,lineterminator="\n")
    dat = {}
    hdr1 = next(r1)

    for row in r1:
        name = re.sub(r' ','_',row[0])
        name = re.sub(r'\.aa\.fasta','',name)
        print("adding ",name)
        if name != "":
            dat[name] = 1

    for row in r2:
        name = row[0]
        tempname = re.sub(r' ','_',name)
        print("name is ",tempname)
        if tempname in dat:
            row.append("Mortierellaceae_MLST")
        else:
            row.append("ZygoLCG")
        out.writerow(row)
