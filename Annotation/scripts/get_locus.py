#!/usr/bin/env python
import csv, re, sys
prefix_name="samples_prefix.csv"

if len(sys.argv) != 2:
    print("expect 1 argument - a genome file name")
    exit()

name=sys.argv[1]
name = re.sub(r' ','_',name)
#print("query is ",name)
with open(prefix_name,"rU") as prefixes:
    proj = csv.reader(prefixes)
    header = next(proj)
#    print("header is ",header)
    #SPECIES,STRAIN,JGILIBRARY,BIOSAMPLE,BIOPROJECT,SRA,LOCUSTAG,TEMPLATE
    for row in proj:
        species = row[0]
        if len(species) == 0:
            continue
        stem = re.sub(r' ','_',species)
        prj = row[4]
        samp = row[3]
        locus = row[6]
        if len(locus) == 0:
            locus = row[2]
        if name == stem:
            print(locus)
            break
