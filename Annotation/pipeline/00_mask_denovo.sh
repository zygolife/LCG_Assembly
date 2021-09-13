#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 8 --nodes 1 --mem 24G --out logs/mask.%a.%A.log

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=genomes

#LIBRARY=lib/zygo_repeats.fasta
SAMPFILE=samples.csv
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
  N=$1
  if [ ! $N ]; then
    echo "need to provide a number by --array or cmdline"
    exit
  fi
fi
MAX=$(wc -l $SAMPFILE | awk '{print $1}')
if [ $N -gt $MAX ]; then
  MAXSMALL=$MAX
  echo "$N is too big, only $MAXSMALL lines in $SAMPFILE"
  exit
fi

IFS=,
tail -n +2 $SAMPFILE | while read SPECIES PHYLUM STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE KEEPLCG DEPOSITASM
do
  name=$(echo "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g')
  species=$(echo "$SPECIES" | perl -p -e "s/\Q$STRAIN\E//")

  if [ ! -f $INDIR/${name}.sorted.fasta ]; then
    echo "Cannot find $name in $INDIR - may not have been run yet"
    exit
  fi

  if [ ! -f $OUTDIR/${name}.masked.fasta ]; then


    module unload miniconda3
    module unload miniconda2
    module unload anaconda3

    #funannotate mask --cpus $CPU -i ../$INDIR/${name}.sorted.fasta -o ../$OUTDIR/${name}.masked.fasta
    if [ -f repeat_library/${name}.repeatmodeler-library.fasta ]; then
      LIBRARY=repeat_library/${name}.repeatmodeler-library.fasta
      LIBRARY=$(realpath $LIBRARY)
    fi
    if [ ! -z $LIBRARY ]; then
      funannotate mask --cpus $CPU -i $INDIR/${name}.sorted.fasta -o $OUTDIR/${name}.masked.fasta -l $LIBRARY -m repeatmasker
    else
      echo "running tantan not repeatmasker as we need to sort out a pre-run of repeatmodeler to proceed with repeatmasker"
      funannotate mask --cpus $CPU -i $INDIR/${name}.sorted.fasta -o $OUTDIR/${name}.masked.fasta -m tantan
    fi
    popd
    rmdir $name.mask.$$
  else
    echo "Skipping ${name} as masked already"
  fi

done
