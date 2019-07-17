#!/usr/bin/bash

N=1
NT=""
AA=""
for file in $(ls genomes/*.sorted.fasta)
do
	BASE=$(basename $file .sorted.fasta)
	if [[ -f taxonomy/$BASE.diamond.tab.taxified.out && ! -f blobOut/$BASE.AA.blobDB.json ]]; then
		if [ -z $NT ]; then
			NT=$N
		else
			NT="$NT,$N"
		fi
	fi
	N=$(expr $N + 1)
done
echo "sbatch -p short --array=$NT pipeline/03_blob.sh"

