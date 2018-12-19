#!/usr/bin/env python3

from Bio import SeqIO
import sys,csv,os

indir='.'

if len(sys.argv) > 1:
    indir = sys.argv[1]

for base in ['meta_16S_rRNA', 'spades_16S_rRNA' ]:
    taxonomy = os.path.join(indir,"%s.classify.tab"%(base))
    taxlookup = {}
    with open(taxonomy,"r") as tax:
        taxparse = csv.reader(tax, delimiter="\t", quotechar='|')
        for row in taxparse:
            otu = row[0]
            taxonlist = []
            for i in range(5,len(row)-4,3):
                score=row[i+2]
                rank=row[i+1]
                name=row[i].strip('"')
                taxonlist.append("%s__%s"%(rank[0],name))

            taxonstr = ";".join(taxonlist)            
            taxlookup[otu] = "%s__%s"%(otu,taxonstr)

    for kingdom in [ 'bacteria', 'archaea', 'eukarya' ]:
        sequences = []
        fname = "%s.%s.fasaln"%(base,kingdom)
        for record in SeqIO.parse(os.path.join(indir,base,fname),"fasta"):
            if record.id in taxlookup:
                record.id = taxlookup[record.id]
            else:
                print("cannot find record.id %s in taxlookup"%(record.id))
            sequences.append(record)
        
        with open(os.path.join(indir,"%s.%s.taxonomy.fasaln"%(base,kingdom)), "w") as output_handle:
            SeqIO.write(sequences, output_handle, "fasta")


