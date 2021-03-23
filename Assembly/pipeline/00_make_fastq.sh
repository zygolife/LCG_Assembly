#!/bin/bash
#SBATCH --nodes 1 --ntasks 1 --mem 8gb -p short -J makeFastq --out logs/make_fastq.%a.log --time 2:00:00

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
#FILE=$(ls $DATA/*.fastq.gz | sed -n ${N}p)
BASE=$(sed -n ${N}p samples.dat | cut -f1)
FILE=($(ls data/1978_*/$BASE.fastq.gz data/1978_*/$BASE.*.fastq.gz 2> /dev/null ))

if [[ ! -f $OUTDIR/${BASE}_R1.fq.gz && ! -s $OUTDIR/${BASE}_R2.fq.gz ]]; then
	rm -f $OUTDIR/${BASE}_R?.fq.gz
	for file in "${FILE[@]}"
	do
		reformat.sh in=$file out1=$OUTDIR/${BASE}_R1.fq.gz out2=$OUTDIR/${BASE}_R2.fq.gz app=true
	done
fi
