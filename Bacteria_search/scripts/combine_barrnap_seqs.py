#!/usr/bin/env python3

from Bio import SeqIO
import os

indir = 'reports/barrnap'
outdir= 'parsed_seqs/barrnap'

seqs = { 'meta': {}, 'spades': {} }
seen = {}
for file in os.listdir(indir):
    ext = ""

    if file.endswith(".metaspades_barrnap.fa"):
        ext = 'meta'
    elif file.endswith(".spades_barrnap.fa"):
        ext = 'spades'

    prefix = file.rsplit('.',2)[0]        
    for record in SeqIO.parse(os.path.join(indir,file),"fasta"):
        (type,ctg) = record.id.split("::")
        (ctgname,rest)  = ctg.split("_length")
        #print(prefix,ext,type,ctgname)
        record.id = "%s_%s"%(prefix,ctgname)
        orig_id = record.id
        if orig_id in seen:
            record.id += ".%d"%(seen[orig_id])
        else:
            seen[orig_id] = 0
        seen[orig_id] += 1
        if type in seqs[ext]:            
            seqs[ext][type].append(record)
        else:
            seqs[ext][type] = [record]

for ext in seqs.keys():
    for type in seqs[ext].keys():
        with open(os.path.join(outdir,"%s_%s.fasta"%(ext,type)), "w") as output_handle:
            SeqIO.write(seqs[ext][type], output_handle, "fasta")
            
        
