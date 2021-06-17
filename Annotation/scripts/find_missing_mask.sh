#!/bin/ksh
#SBATCH -p short logs/find_missing_masked.log

CPU=1

INDIR=genomes
OUTDIR=genomes
SAMPFILE=samples_prefix.csv
IFS=,
N=1
TOMASK=()
tail -n +2 $SAMPFILE | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
  name=$(echo "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g')
  if [ ! -f $INDIR/${name}.sorted.fasta ]; then
    TOADD+=( $N )
    echo "missing $name.sorted.fasta"
  elif [[ ! -f $OUTDIR/${name}.masked.fasta ]]; then
    TOMASK+=($N)
    echo "missing $name.masked.fasta"
  fi
  N=$(expr $N + 1)
done

MISSING=$(echo "${TOMASK[@]}" | perl -p -e 's/ /,/g')

echo "sbatch --array=$MISSING pipeline/00_mask.sh"
