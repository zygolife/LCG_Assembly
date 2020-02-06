#!/usr/bin/env python
import csv, re, sys, os
template = "submit_files/template_%s.sbt"
outdir = "submit_files"
prefix_name="samples_prefix.csv"

with open(prefix_name,"rU") as prefixes:
    proj = csv.reader(prefixes)
    header = next(proj)
#    print("header is ",header)
    #SPECIES,JGILIBRARY,BIOSAMPLE,BIOPROJECT,SRA,LOCUSTAG
    for row in proj:
        species = row[0]
        if len(species) == 0:
            continue
        stem = re.sub(r' ','_',species)
        prj = row[3]
        samp = row[2]
        template_name = row[6]
        templatefile = template%(template_name)
        if not os.path.exists("%s/%s.sbt"%(outdir,stem)):
            print("perl -p -e 's/BIOPROJECTID/%s/; s/BIOSAMPLEID/%s/' %s > %s/%s.sbt"%(
                prj,samp,templatefile,outdir,stem))
