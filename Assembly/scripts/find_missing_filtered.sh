#!/usr/bin/bash
n=1
while read strain domain; 
do 
    if [[ ! -f genomes/${strain}.spades.fasta && ! -f working_AAFTF/${strain}_filtered_1.fastq.gz ]]; then 
	echo "$n $strain"
    fi 
    n=$(expr $n + 1);
done < samples.dat

n=1

m=$(while read strain domain; do 
    if [[ ! -f genomes/${strain}.spades.fasta && ! -f working_AAFTF/${strain}_filtered_1.fastq.gz ]]; then 
	echo "$n"
    fi
    n=$(expr $n + 1); 
done < samples.dat | perl -p -e 's/\n/,/' | perl -p -e 's/,$//')
echo "sbatch --array=$m pipeline/01_AAFTF_filter.sh"
