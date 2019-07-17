#!/usr/bin/bash

N=1
NT=""
for file in $(ls genomes/*.sorted.fasta)
do
	BASE=$(basename $file .sorted.fasta)
	if [ ! -f bam/$BASE.remap.bam ]; then
		if [ -z $NT ]; then
			NT=$N
		else
			NT="$NT,$N"
		fi
	fi
	N=$(expr $N + 1)
done
echo "sbatch -p short --array=$NT pipeline/02_make_cov.sh"

