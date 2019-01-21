#!/bin/bash
#SBATCH --nodes 1 --ntasks 1 --mem 8gb -p short -J split_fastq --out logs/make_fastq.%a.log --time 2:00:00

CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

module load BBMap

OUTDIR=input
DATA=data/1978_Plate?
FILE=$(ls $DATA/*.fastq.gz | sed -n ${N}p)
BASE=$(basename $FILE .fastq.gz)

if [ ! -e $OUTDIR/${BASE}_R1.fq.gz ]; then
	reformat.sh in=$FILE out1=$OUTDIR/${BASE}_R1.fq.gz out2=$OUTDIR/${BASE}_R2.fq.gz
fi
