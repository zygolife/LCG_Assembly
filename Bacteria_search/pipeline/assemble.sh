#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 8 --mem 32G --out logs/assemble.%a.log --time 4:00:00 -p batch

MEM=32
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}
TEMP=/scratch
if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

module load SPAdes

INDIR=results
OUTPUT=asm
SAMPLEFILE=samples.dat
BASE=$(sed -n ${N}p $SAMPLEFILE | cut -f1)
SUBPHYLUM=$(sed -n ${N}p $SAMPLEFILE | cut -f3)
if [ ! -f $INDIR/${BASE}_R1.filter1.fq.gz ]; then
	echo "Cannot run as $INDIR/${BASE}_R1.filter1.fq.gz missing"
	exit
elif [ ! -d $OUTPUT/${BASE}.spades ]; then
	spades.py --threads $CPU --mem $MEM -1 $INDIR/${BASE}_R1.filter1.fq.gz -2 $INDIR/${BASE}_R2.filter1.fq.gz --tmp-dir $TEMP -o $OUTPUT/${BASE}.spades --cov-cutoff auto --careful 
else
    echo "skipping already started/run $BASE.spades in $OUTDIR"
    exit
fi
