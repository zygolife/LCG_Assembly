#!/bin/bash
#SBATCH -p batch,intel --time 2-0:00:00 --ntasks 8 --nodes 1 --mem 24G --out logs/mask.%a.%A.log
module load workspace/scratch
CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=$(realpath genomes)
OUTDIR=$(realpath genomes)
LIBRARY=$(realpath lib/zygo_repeats.fasta)

SAMPFILE=samples_prefix.csv
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
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
#SPECIES,STRAIN,JGILIBRARY,BIOSAMPLE,BIOPROJECT,TAXONOMY_ID,ORGANISM_NAME,SRA_SAMPID,SRA_RUNID,LOCUSTAG,TEMPLATE
#ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note

tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
 name=$(echo "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g')
 fixedname=$(echo $name | perl -p -e 's/\+/Plus/')

 if [[ $name != $fixedname ]]; then
     echo "A plus in the name $name, need to rename to $fixednamed"
     exit
 fi
 if [ ! -f $INDIR/${name}.sorted.fasta ]; then
     echo "Cannot find $name in $INDIR - may not have been run yet"
     exit
 fi

 if [ ! -f $OUTDIR/${name}.masked.fasta ]; then
     module load funannotate
     export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)
   # export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config
     
     #funannotate mask --cpus $CPU -i ../$INDIR/${name}.sorted.fasta -o ../$OUTDIR/${name}.masked.fasta
     if [ -f repeat_library/${name}.repeatmodeler-library.fasta ]; then
	 LIBRARY=repeat_library/${name}.repeatmodeler-library.fasta
     fi
     LIBRARY=$(realpath $LIBRARY)
     cwd=`pwd`
     pushd $SCRATCH
     rsync -La $INDIR/${name}.sorted.fasta .
     funannotate mask --cpus $CPU -i ${name}.sorted.fasta -o ${name}.masked.fasta -l $LIBRARY -m repeatmasker
     mv ${name}.masked.fasta $OUTDIR
     mv funannotate-mask.log $cwd/logs/${name}.mask.log
     popd
 else 
     echo "Skipping ${name} as masked already"
 fi
done
