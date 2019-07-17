#!/usr/bin/bash

N=1
NT=""
AA=""
for file in $(ls genomes/*.sorted.fasta)
do
	BASE=$(basename $file .sorted.fasta)
	if [ ! -f taxonomy/$BASE.nt.blastn.tab ]; then
		if [ -z $NT ]; then
			NT=$N
		else
			NT="$NT,$N"
		fi
	fi
	if [ ! -f taxonomy/$BASE.diamond.tab ]; then
		if [ -z $AA ]; then
			AA=$N
		else
			AA="$AA,$N"
		fi
	fi
	N=$(expr $N + 1)
done
echo "sbatch -p batch --array=$NT pipeline/01_blastn.sh"
echo "R=\$(sbatch -p batch --array=$AA pipeline/01_diamond.sh)"
echo "R=\$(echo "\$R" | awk '{print \$4}')"
echo "sbatch  --dependency=afterok:\$R -p batch --array=$AA pipeline/01b_diamond_taxify.sh"

