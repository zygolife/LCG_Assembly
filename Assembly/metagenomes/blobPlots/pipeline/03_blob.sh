#!/usr/bin/bash
#SBATCH -p short --mem 8gb -N 1 -n 1 --out logs/blob.%a.log

module load blobtools/1.1.1
source activate blobtools

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
 CPU=$SLURM_CPUS_ON_NODE
fi

N=${SLURM_ARRAY_TASK_ID}
if [ -z $N ]; then
 N=$1
fi

if [ -z $N ]; then
 echo "need to provide a number by --array or cmdline"
 exit
fi
OUT=blobOut
mkdir -p $OUT
ASSEMBLY=$(ls genomes/*.sorted.fasta | sed -n ${N}p)
BASE=$(basename $ASSEMBLY .sorted.fasta)
BAM=bam/$BASE.remap.bam
NTTAX=taxonomy/$BASE.nt.blastn.tab
PROTTAB=taxonomy/$BASE.diamond.tab
PROTTAX=taxonomy/$BASE.diamond.tab.taxified.out

if [ ! -f $BASE.NT.blobDB.json ]; then
    blobtools create -i $ASSEMBLY -b $BAM -t $NTTAX -o $OUT/$BASE.NT
fi

if [ ! -f $BASE.AA.blobDB.json ]; then
    blobtools create -i $ASSEMBLY -b $BAM -t $PROTTAX -o $OUT/$BASE.AA
fi
pushd $OUT

time blobtools view -r all -i $BASE.NT.blobDB.json

for rank in phylum order
do
    if [ ! -f $BASE.NT.blobDB.json.bestsum.$rank.p8.span.100.blobplot.read_cov.bam0.png ]; then
	blobtools plot -i $BASE.NT.blobDB.json -r $rank
    fi
done

time blobtools view -r all -i $BASE.AA.blobDB.json

for rank in phylum order
do
    if [ ! -f $BASE.AA.blobDB.json.bestsum.$rank.p8.span.100.blobplot.read_cov.bam0.png ]; then
	blobtools plot -i $BASE.AA.blobDB.json -r $rank
    fi
done
