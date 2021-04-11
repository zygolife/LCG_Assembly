#!/usr/bin/env python3

import csv, re, sys, os, argparse
import xml.etree.ElementTree as ET
from Bio import Entrez

separator = ","
multilistsep = ";"
parser = argparse.ArgumentParser(description='Get BioProject, SRA data, and Locus Prefix for records.')
parser.add_argument('-i', '--input', metavar='in', default="samples.csv", required=False,
                    help='Input file to read (samples.csv)')
parser.add_argument('-o', '--output', metavar='out', default="samples_prefix.csv", required=False,
                    help='Output file to write (samples_prefix.csv)')

parser.add_argument('--debug', required = False, action='store_true',
                    help='Debug this running')

parser.add_argument('-e', '--email', default="jason.stajich@ucr.edu",required=False,
                    help='Email for Entrez queries')

args = parser.parse_args()

if not (args.output.endswith(".csv") or args.output.endswith(".CSV")):
    separator = "\t"

Entrez.email = args.email

def indent(elem, level=0):
    i = "\n" + level*"  "
    j = "\n" + (level-1)*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for subelem in elem:
            indent(subelem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = j
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = j
    return elem


if __name__ == '__main__':
    seen = {}
    outrows = {}
    if os.path.exists(args.output):
        with open(args.output,"rU") as preprocess:
            incsv = csv.reader(preprocess,delimiter=separator)
            h = next(incsv)
            for row in incsv:
                key = re.sub(r'\s+','_',row[0] + "_" + row[1])
                row[2] = set([row[2]])
                outrows[key] = row


    with open(args.input,"rU") as infh, open(args.output,"wt",newline="") as outfh:
        outcsv    = csv.writer(outfh,delimiter=separator)
        outcsv.writerow(['SPECIES','STRAIN','JGILIBRARY',
                         'BIOSAMPLE','BIOPROJECT','TAXONOMY_ID','ORGANISM_NAME','SRA_SAMPID','SRA_RUNID',
                         'LOCUSTAG','TEMPLATE'])

        samplescsv = csv.reader(infh,delimiter=separator)
        for row in samplescsv:
            species = row[5] # species has strain info in it
            strain = row[6]
            jgilib = row[2]
            key = re.sub(r'\s+','_',row[5] + "_" + strain)
            if key in outrows:
                outrows[key][2].add(jgilib) # since this is a set we just always add it and it will stay unique list
                if len(outrows[key][3]) > 0:
                    continue

            outrow = [row[5],row[6], set([row[2]])]

            handle = Entrez.esearch(db="biosample",retmax=10,term=species)
            record = Entrez.read(handle)
            handle.close()
            SRA_SAMPLEID = ""
            BIOSAMPLE = ""
            BIOPROJECT = ""
            LOCUSTAG = ""
            BIOPROJECTID=""
            TAXONOMY_ID = ''
            TAXONOMY_NAME = ''
            SRA_RUNID = []
            TEMPLATE="ZygoLCG"
            for biosampleid in record["IdList"]:
                handle = Entrez.efetch(db="biosample", id=biosampleid)
                tree = ET.parse(handle)
                root = tree.getroot()
                for sample in root:
                    BIOSAMPLE = sample.attrib['accession']
                    #indent(sample)
                    #ET.dump(sample)
                    for ids in root.iter('Ids'):
                        #indent(ids)
                        #ET.dump(ids)
                        for id in ids.iter('Id'):
                            if 'db' in id.attrib and id.attrib['db'] == "SRA":
                                SRA_SAMPLEID = id.text
                    for links in root.iter('Links'):
                        for link in links:
                            linkdat = link.attrib
                            if linkdat['type'] == 'entrez' and 'label' in linkdat:
                                BIOPROJECT = linkdat['label']
                                BIOPROJECTID = link.text
                    for org in root.iter('Organism'):
                        #indent(org)
                        #ET.dump(org)
                        TAXONOMY_ID   = org.attrib['taxonomy_id']
                        TAXONOMY_NAME = org.attrib['taxonomy_name']
                sra_handle = Entrez.elink(dbfrom='biosample',db='sra',id = biosampleid)
                sra_tree = ET.parse(sra_handle)
                sra_root = sra_tree.getroot()
                sraid = ""
                for link in sra_root.iter('Link'):
                    for id in link:
                        sraid = id.text
                        break
                sra_handle = Entrez.efetch(db='sra',id = sraid)
                sra_tree   = ET.parse(sra_handle)
                sra_root   = sra_tree.getroot()
                for runset in sra_root.iter('RUN_SET'):
                    for run in runset:
                        SRA_RUNID.append(run.attrib['accession'])

            if BIOPROJECTID:
                bioproject_handle = Entrez.efetch(db="bioproject",id = BIOPROJECTID)
                projtree = ET.parse(bioproject_handle)
                projroot = projtree.getroot()
                #indent(projroot)
                #ET.dump(projroot)
                lt = projroot.iter('LocusTagPrefix')
                for locus in lt:
                    LOCUSTAG = locus.text

                #for id in sra_root.iter('Ids'):
                #    indent(id)
                #    ET.dump(id)

            outrow.extend([BIOSAMPLE,BIOPROJECT,TAXONOMY_ID, TAXONOMY_NAME,
                            SRA_SAMPLEID,SRA_RUNID,LOCUSTAG,TEMPLATE])
            outrows[key] = outrow

        for rowid in sorted(outrows):
            row = outrows[rowid]
            row[2] = multilistsep.join(row[2]) # undo the set and make it a ';' separated string
            row[8] = multilistsep.join(row[8])
            outcsv.writerow(row)
