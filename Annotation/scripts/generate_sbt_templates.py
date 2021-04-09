#!/usr/bin/env python
import csv, re, sys, os
template = "submit_files/template_%s.sbt"
outdir = "submit_files"
prefix_name="samples_prefix.csv"

with open(prefix_name,"rU") as prefixes:
    proj = csv.reader(prefixes)
    header = next(proj)
#    print("header is ",header)
    #SPECIES,STRAIN,JGILIBRARY,BIOSAMPLE,BIOPROJECT,SRA,LOCUSTAG,TEMPLATETYPE
    for row in proj:
        species = row[0]
        if len(species) == 0:
            continue
        stem = re.sub(r' ','_',species)
        strain = row[1]
        prj = row[4]
        samp = row[3]
        if len(row) < 8:
            print("error on line {} is length {}".format(row,len(row)))
            break
        template_name = row[7]
        templatefile = template%(template_name)
        if not os.path.exists("%s/%s.sbt"%(outdir,stem)):
            print("perl -p -e 's/BIOPROJECTID/%s/; s/BIOSAMPLEID/%s/' %s > %s/%s.sbt"%(
                prj,samp,templatefile,outdir,stem))
