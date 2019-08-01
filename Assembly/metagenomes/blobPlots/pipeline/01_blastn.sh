#!/usr/bin/bash
#SBATCH -p batch --mem 64gb -N 1 -n 24 --out logs/blastn_nt.%a.log --time 48:00:00


module load ncbi-blast/2.9.0+

DB=/srv/projects/db/NCBI/preformatted/20190709/nt

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
if [ ! -f $OUT.nt.blastn.tab ]; then
blastn \
 -query $ASSEMBLY \
 -db $DB \
 -outfmt '6 qseqid staxids bitscore std' \
 -max_target_seqs 10 \
 -max_hsps 1 -num_threads $CPU \
 -evalue 1e-25 -out $OUT.nt.blastn.tab
fi
