#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 16 --nodes 1 --mem 24G --out logs/genemark_train.%a.log
module unload miniconda3
module unload miniconda2
module unload anaconda3
module load funannotate
module load workspace/scratch

export FUNANNOTATE_DB=/bigdata/stajichlab/shared/lib/funannotate_db
#
#GMFOLDER=`dirname $(which gmhmme3)`

# make genemark key link required to run it
#if [ ! -f ~/.gm_key ]; then
#    ln -s $GMFOLDER/.gm_key ~/.gm_key
#fi

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
  CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=$(realpath genomes)
OUTDIR=$(realpath annotate)
SAMPFILE=samples_prefix.csv
INFORMANT=$(realpath lib/informant.2.aa)
BUSCO=mucoromycota_odb10
N=${SLURM_ARRAY_TASK_ID}

if [ ! $N ]; then
  N=$1
  if [ ! $N ]; then
    echo "need to provide a number by --array or cmdline"
    exit
  fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
  echo "$N is too big, only $MAX lines in $SAMPFILE"
  exit
fi
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES PHYLUM STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE KEEPLCG DEPOSITASM
do
  name=$(echo -n "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g')
  species=$(echo -n "$SPECIES" | perl -p -e "chomp; s/\s*\Q$STRAIN\E//; chomp")
  if [ ! -f $INDIR/$name.masked.fasta ]; then
    echo "No genome for $INDIR/$name.masked.fasta yet - run 00_mask.sh $N"
    exit
  fi
  prefix=$LOCUSTAG
  if [ -z $prefix ]; then
    prefix=$JGILIBRARY
  fi

  if [ ! -f $INDIR/$name.masked.fasta ]; then
    echo "No genome for $INDIR/$name.masked.fasta yet - run 00_mash.sh $N"
    exit
  fi
  if [ ! -d $OUTDIR/$name/predict_misc ]; then
    echo "need to have run an initial funannotate"
    exit
  fi

  if [ -f $OUTDIR/$name/predict_misc/gmhmm.mod ]; then
    echo "already have a gmhmm.mod file in $OUTDIR/$name/predict_misc - will run"
    if [ ! -f $OUTDIR/$name/predict_misc/genemark/genemark.gtf ]; then
        mkdir -p $OUTDIR/$name/predict_misc/genemark
        pushd $OUTDIR/$name/predict_misc/genemark
        gmes_petap.pl --ES --fungus --prediction --sequence ../genome.softmasked.fa --cores $CPU --predict_with $OUTDIR/$name/predict_misc/gmhmm.mod
        popd
    fi
  else
    mkdir -p $OUTDIR/$name/predict_misc/genemark
    pushd $OUTDIR/$name/predict_misc/genemark
    gmes_petap.pl --min_contig 5000 --ES --fungus --sequence ../genome.softmasked.fa --cores $CPU
    popd
  fi
  if [ -f output/gmhmm.mod ]; then
    rsync output/gmhmm.mod ..
  else
    echo "cannot find genemark.gtf, run failed?"
  fi
done
