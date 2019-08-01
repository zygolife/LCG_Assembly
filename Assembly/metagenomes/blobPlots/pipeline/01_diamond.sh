#!/usr/bin/bash
#SBATCH -p batch --mem 16gb -N 1 -n 8 --out logs/diamond.%a.log --time 48:00:00


module load diamond

DB=uniprot_ref_proteomes.diamond.dmnd

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
mkdir -p taxonomy
ASSEMBLY=$(ls genomes/*.sorted.fasta | sed -n ${N}p)
OUT=taxonomy/$(basename $ASSEMBLY .sorted.fasta)


if [ ! -f $OUT.diamond.tab ]; then
    diamond blastx \
	--query $ASSEMBLY \
	--db $DB \
	--outfmt 6 \
	--sensitive \
	--max-target-seqs 1 \
	--evalue 1e-25 --threads $CPU --out $OUT.diamond.tab
fi
