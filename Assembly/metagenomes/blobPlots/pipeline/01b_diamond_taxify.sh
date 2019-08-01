#!/usr/bin/bash
#SBATCH -p batch --mem 128gb -N 1 -n 2 --out logs/diamond_taxify.%a.log

module load blobtools/1.1.1
source activate blobtools

N=${SLURM_ARRAY_TASK_ID}
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
 CPU=$SLURM_CPUS_ON_NODE
fi


if [ -z $N ]; then
 N=$1
fi

if [ -z $N ]; then
 echo "need to provide a number by --array or cmdline"
 exit
fi

ASSEMBLY=$(ls genomes/*.sorted.fasta | sed -n ${N}p)
OUT=$(basename $ASSEMBLY .sorted.fasta)
OUTDIR=taxonomy
# taxify results
pushd $OUTDIR
if [ ! -f $OUT.diamond.tab.taxified.out ]; then
    blobtools taxify -f $OUT.diamond.tab -m ../uniprot_ref_proteomes.taxids -s 0 -t 2
fi
