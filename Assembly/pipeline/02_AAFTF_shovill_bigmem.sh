#!/bin/bash
#SBATCH --nodes 1 --ntasks 16 --mem 120gb -J zygoShovill --out logs/AAFTF_shovill.%a.%A.log -p intel --time 64:00:00
source ~/.bashrc
hostname
MEM=120
CPU=$SLURM_CPUS_ON_NODE
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "Need an array id or cmdline val for the job"
        exit
    fi
fi

module load AAFTF

OUTDIR=input
SAMPLEFILE=samples.dat
BASE=$(sed -n ${N}p $SAMPLEFILE | cut -f1)
PHYLUM=$(sed -n ${N}p $SAMPLEFILE | cut -f2)
ASM=genomes
TMPDIR=/scratch/$USER
MINLEN=500

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

LEFT=$WORKDIR/${BASE}_filtered_1.fastq.gz
RIGHT=$WORKDIR/${BASE}_filtered_2.fastq.gz

mkdir -p $WORKDIR

echo "$BASE"
if [ ! -f $ASMFILE ]; then    
    if [ ! -f $LEFT ]; then
	echo "Cannot find LEFT $LEFT or RIGHT $RIGHT - did you run"
	echo "$OUTDIR/${BASE}_R1.fq.gz $OUTDIR/${BASE}_R2.fq.gz"
	exit
    fi
    module unload miniconda2
    module load miniconda3
    module unload perl
    conda activate shovill

    shovill --cpu $CPU --ram $MEM --outdir $WORKDIR/shovill_${BASE} \
	--R1 $LEFT --R2 $RIGHT --nocorr --depth 90 --tmpdir $TMPDIR --minlen $MINLEN

    if [ -f $WORKDIR/shovill_${BASE}/contigs.fa ]; then
	rsync -a $WORKDIR/shovill_${BASE}/contigs.fa $ASMFILE
    else	
	echo "Cannot find $WORKDIR/shovill_${BASE}/contigs.fa"
	exit
    fi
    conda deactivate 
    
    if [ -s $ASMFILE ]; then
	rm -rf $WORKDIR/shovill_${BASE}
    else
	echo "SPADES must have failed, exiting"
	exit
    fi
fi

if [ ! -f $VECCLEAN ]; then
    AAFTF vecscreen -i $ASMFILE -c $CPU -o $VECCLEAN 
fi

if [ ! -f $PURGE ]; then
    AAFTF sourpurge -i $VECCLEAN -o $PURGE -c $CPU --phylum $PHYLUM --left $LEFT  --right $RIGHT
fi

if [ ! -f $CLEANDUP ]; then
   AAFTF rmdup -i $PURGE -o $CLEANDUP -c $CPU -m 1000
fi

if [ ! -f $PILON ]; then
   AAFTF pilon -i $CLEANDUP -o $PILON -c $CPU --left $LEFT  --right $RIGHT 
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
