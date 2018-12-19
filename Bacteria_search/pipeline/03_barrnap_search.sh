#!/usr/bin/bash
#SBATCH -p short --ntasks 2 --nodes 1 --mem 2G --out logs/barnap.%a.log

module load barrnap

CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

INDIR=genomes
OUTPUT=reports/barrnap
mkdir -p $OUTPUT

SAMPLEFILE=samples.dat
BASE=$(sed -n ${N}p $SAMPLEFILE | cut -f1)
SUBPHYLUM=$(sed -n ${N}p $SAMPLEFILE | cut -f3)

if [ ! -L $INDIR/${BASE}.spades.fasta ]; then
	echo "skipping spades not found for $INDIR/${BASE}.spades.fasta"
elif [ ! -f $OUTPUT/${BASE}.spades_barrnap.gff3 ]; then
    barrnap --kingdom bac --threads $CPU --reject 0.01 --lencutoff 0.5 --outseq $OUTPUT/${BASE}.spades_barrnap.fa $INDIR/${BASE}.spades.fasta > $OUTPUT/${BASE}.spades_barrnap.gff3
fi

if [ ! -L $INDIR/${BASE}.metaspades.fasta ]; then 
	echo "skipping metaspades not found for $INDIR/${BASE}.metaspades.fasta"
elif [ ! -f $OUTPUT/${BASE}.metaspades_barrnap.gff3 ]; then
    barrnap --kingdom bac --threads $CPU --reject 0.01 --lencutoff 0.5 --outseq $OUTPUT/${BASE}.metaspades_barrnap.fa $INDIR/${BASE}.metaspades.fasta > $OUTPUT/${BASE}.metaspades_barrnap.gff3
fi


