#!/usr/bin/bash
#SBATCH --nodes 1 --ntasks 8 --mem 16G --out logs/subtract.%a.log --time 2:00:00 -p short

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

INDIR=input
OUTPUT=results
DB=ref_dbs
SAMPLEFILE=samples.dat
BASE=$(sed -n ${N}p $SAMPLEFILE | cut -f1)
SUBPHYLUM=$(sed -n ${N}p $SAMPLEFILE | cut -f3)
REFFILE=""
if [[ $SUBPHYLUM == "Mucoromycotina" ]]; then
    REFFILE=Mucor_Rhizopus.fa
elif [[ $SUBPHYLUM == "Mortirellomycotina" ]]; then
    REFFILE=Mortierella.fa
else
    echo "Skipping $BASE"
    exit
fi
if [ ! -f $OUTPUT/${BASE}_R1.filter1.fq.gz ]; then
    bbduk.sh in=$INDIR/${BASE}_R1.fq.gz in2=$INDIR/${BASE}_R2.fq.gz out=$OUTPUT/${BASE}_R1.filter1.fq.gz out2=$OUTPUT/${BASE}_R2.filter1.fq.gz ref=$DB/$REFFILE
else
    echo "skipping already seen R1 for $BASE in $OUTDIR"
    exit
fi
