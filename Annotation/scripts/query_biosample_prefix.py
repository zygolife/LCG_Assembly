#!/usr/bin/env python3

import csv, re, sys, os
import xml.etree.ElementTree as ET
from Bio import Entrez
Entrez.email = 'jason.stajich@ucr.edu'
insamples = "samples.csv"
outsamples="samples_prefix.csv"
DEFAULTTEMPLATE="ZygoLCG"

if len(sys.argv) > 1:
    insamples = sys.argv[1]

if len(sys.argv) > 2:
    outsamples = sys.argv[2]

seen = {}
if os.path.exists(outsamples):
    with open(outsamples,"rU") as preprocess:
        incsv = csv.reader(preprocess,delimiter=",")
        h = next(incsv)
        for row in incsv:
            if len(row) != 8:
                print(row)
                exit()
            name = "%s %s"%(row[0],row[1])
            print('storing %s for previous see'%(name))
            seen[name] = row

with open(insamples,"rU") as infh, open(outsamples,"w") as outfh:
    outcsv    = csv.writer(outfh,delimiter=",",lineterminator="\n")
    outcsv.writerow(['SPECIES','STRAIN','JGILIBRARY','BIOSAMPLE','BIOPROJECT','SRA','LOCUSTAG','TEMPLATE'])

    samplescsv = csv.reader(infh,delimiter=",")
    for row in samplescsv:
        name = row[5]
        strain = row[6]
        JGILIB = row[2]
        name = re.sub(strain,'',name)
        name = re.sub('\s+$','',name)
        lookup = "%s %s"%(name,strain)
        outrow = [name,strain,JGILIB]
        print("name is '%s' strain is '%s' lname=%s"%(name,strain,lookup))
        if lookup in seen and len(seen[lookup][2]) > 0:
            outrow = seen[lookup]
            if len(outrow[7]) == 0:
                outrow[7] = DEFAULTTEMPLATE
            outcsv.writerow(outrow)
            outfh.flush()
            continue
        else:
            print("doing a lookup for %s"%(lookup))

        handle = Entrez.esearch(db="biosample",retmax=10,term=lookup)
        record = Entrez.read(handle)
        handle.close()
        SRA = ""
        BIOSAMPLE = ""
        BIOPROJECT = ""
        LOCUSTAG = ""
        BIOPROJECTID=""
        for biosampleid in record["IdList"]:
            handle = Entrez.efetch(db="biosample", id=biosampleid)
            tree = ET.parse(handle)
            root = tree.getroot()
            for sample in root:
                BIOSAMPLE = sample.attrib['accession']
                for ids in root.iter('Ids'):
                    for id in ids.iter('Id'):
                        if 'db' in id.attrib and id.attrib['db'] == "SRA":
                            SRA = id.text
                        elif 'db' not in id.attrib:
                            print("missing db or SRA")
                            print( ET.tostring(root))
                            for k in id.attrib:
                                print("   have %s = %s"%(k,id.attrib[k]))

                for links in root.iter('Links'):
                    for link in links:
                        linkdat = link.attrib
                        if 'type' in linkdat and linkdat['type'] == 'entrez' and 'label' in linkdat:
                            BIOPROJECT = linkdat['label']
                            BIOPROJECTID = link.text
        if BIOPROJECTID:
            bioproject_handle = Entrez.efetch(db="bioproject",id = BIOPROJECTID)
            projtree = ET.parse(bioproject_handle)
            projroot = projtree.getroot()

            lt = projroot.iter('LocusTagPrefix')
            for locus in lt:
                LOCUSTAG = locus.text
        outrow.extend([BIOSAMPLE,BIOPROJECT,SRA,LOCUSTAG,DEFAULTTEMPLATE])
        outcsv.writerow(outrow)
        outfh.flush()
