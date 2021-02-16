#!/bin/bash
#SBATCH -p batch --time 2-0:00:00 --ntasks 8 --nodes 1 --mem 24G --out logs/mask.%a.%A.log

CPU=1
if [ $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=genomes
LIBRARY=lib/zygo_repeats.fasta
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
cat $SAMPFILE | sed -n ${N}p | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
 name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g')
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
module unload python
module unload perl
module load funannotate/1.8.0

export AUGUSTUS_CONFIG_PATH=$(realpath lib/augustus/3.3/config)

   # export AUGUSTUS_CONFIG_PATH=/bigdata/stajichlab/shared/pkg/augustus/3.3/config

    #funannotate mask --cpus $CPU -i ../$INDIR/${name}.sorted.fasta -o ../$OUTDIR/${name}.masked.fasta
if [ -f repeat_library/${name}.repeatmodeler-library.fasta ]; then
	    LIBRARY=repeat_library/${name}.repeatmodeler-library.fasta
fi
    LIBRARY=$(realpath $LIBRARY)
    mkdir $name.mask.$$
    pushd $name.mask.$$
    funannotate mask --cpus $CPU -i ../$INDIR/${name}.sorted.fasta -o ../$OUTDIR/${name}.masked.fasta -l $LIBRARY -m repeatmasker
    mv funannotate-mask.log ../logs/${name}.mask.log
    popd
    rmdir $name.mask.$$
else 
    echo "Skipping ${name} as masked already"
fi
done
