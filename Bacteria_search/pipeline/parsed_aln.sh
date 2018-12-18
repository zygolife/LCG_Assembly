#!/usr/bin/bash
#SBATCH --mem 32G --time 12:00:00  --out logs/aln.log

module load muscle

puhsd parsed_seqs/barrnap

for file in *.fasta
do
	b=$(basename $file .fasta)
	muscle -in $file -quiet -out $b.fasaln
done
