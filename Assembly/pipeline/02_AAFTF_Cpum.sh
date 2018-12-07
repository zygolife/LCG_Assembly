#!/bin/bash
#SBATCH --nodes 1 --ntasks 32 --mem 192gb -J CpumAAFTF --out logs/AAFTF2_asm_Cpum.%A.log -p intel --time 7-0:00:00

hostname
MEM=192
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}
MIN_LEN=1000

module load AAFTF/git-live

OUTDIR=input
PHYLUM=Zoopagomycota
ASM=genomes

mkdir -p $ASM

if [ -z $CPU ]; then
    CPU=1
fi

BASE=Conidiobolus_pumilus_ARSEF_6383
ASMFILE=$ASM/${BASE}.masurca.fasta
WORKDIR=working_AAFTF
VECCLEAN=$ASM/${BASE}.masurca.vecscreen.fasta
PURGE=$ASM/${BASE}.masurca.sourpurge.fasta
CLEANDUP=$ASM/${BASE}.masurca.rmdup.fasta
PILON=$ASM/${BASE}.masurca.pilon.fasta
SORTED=$ASM/${BASE}.masurca.sorted.fasta
STATS=$ASM/${BASE}.masurca.sorted.stats.txt

LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz

mkdir -p $WORKDIR

echo "$BASE"

if [ ! -f $VECCLEAN ]; then
    AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN 
fi

if [ ! -f $PURGE ]; then
    AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT  --right $RIGHT
fi

#if [ ! -f $CLEANDUP ]; then
#   AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m $MIN_LEN
#fi

if [ ! -f $PILON ]; then
   AAFTF pilon -i $PURGE -o $PILON -c $CPU --left $LEFT --right $RIGHT 
fi

if [ ! -f $PILON ]; then
    echo "Error running Pilon, did not create file. Exiting"
    exit
fi

if [ ! -f $SORTED ]; then
    AAFTF sort -i $PILON -o $SORTED
fi

if [ ! -f $STATS ]; then
    AAFTF assess -i $SORTED -r $STATS
fi
