#!/bin/bash
#SBATCH --nodes 1 --ntasks 8 --mem 256gb -p highmem -J zygoAFTF1 --out logs/AAFTF_filter.%a.%A.log --time 2:00:00

hostname
#MEM=512
MEM=256
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

module load AAFTF/git-live

OUTDIR=input
SAMPLEFILE=samples.dat
BASE=$(sed -n ${N}p $SAMPLEFILE | cut -f1)
PHYLUM=$(sed -n ${N}p $SAMPLEFILE | cut -f2)
ASM=genomes

mkdir -p $ASM

if [ -z $CPU ]; then
    CPU=1
fi

ASMFILE=$ASM/${BASE}.spades.fasta
WORKDIR=working_AAFTF
VECCLEAN=$ASM/${BASE}.vecscreen.fasta
PURGE=$ASM/${BASE}.sourpurge.fasta
CLEANDUP=$ASM/${BASE}.rmdup.fasta
PILON=$ASM/${BASE}.pilon.fasta
SORTED=$ASM/${BASE}.sorted.fasta
STATS=$ASM/${BASE}.sorted.stats.txt
LEFTTRIM=$WORKDIR/${BASE}_1P.fastq.gz
RIGHTTRIM=$WORKDIR/${BASE}_2P.fastq.gz

LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz

mkdir -p $WORKDIR

echo "$BASE"
if [[ ! -f $ASMFILE || ! -f $SORTED ]]; then    
    if [ ! -f $LEFT ]; then
	echo "$OUTDIR/${BASE}_R1.fq.gz $OUTDIR/${BASE}_R2.fq.gz"
	if [ ! -f $LEFTTRIM ]; then
	    AAFTF trim --method bbduk --memory $MEM --left $OUTDIR/${BASE}_R1.fq.gz --right $OUTDIR/${BASE}_R2.fq.gz -c $CPU -o $WORKDIR/${BASE}
	fi
	echo "$LEFTTRIM $RIGHTTRIM"
	AAFTF filter -c $CPU --memory $MEM -o $WORKDIR/${BASE} --left $LEFTTRIM --right $RIGHTTRIM --aligner bbduk -a NC_010943.1 CP014274.1 CP017483.1 CP011305.1 CP022053.1 CP007638.1 CP023269.1  NC_000964.3 NC_004461.1 PPHT00000000.1
	#
	echo "$LEFT $RIGHT"
	if [ -f $LEFT ]; then
	    unlink $LEFTTRIM
	    unlink $RIGHTTRIM
	else
	    echo "Error in AAFTF filter"
	fi
    fi
fi
#sbatch --array=$N pipeline/02_AAFTF.sh
