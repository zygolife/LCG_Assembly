#!/usr/bin/bash
#SBATCH --ntasks 8 --nodes 1 --mem 24G -p short --out iprscan_rerun_array.%a.log
module load iprscan
module unload perl

CPU=1
date
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
	    CPU=$SLURM_CPUS_ON_NODE
fi
N=${SLURM_ARRAY_TASK_ID}
if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
f=$(ls *.fasta | sed -n ${N}p)
echo "running $f"
if [ ! -s $f.xml ]; then
	# time interproscan.sh -f xml -i $f --cpu $SPLIT_CPU --disable-precalc > $f.log
	time interproscan.sh -f xml -i $f --cpu $CPU > $f.log
fi
