#!/bin/bash
#SBATCH --nodes 1 --ntasks 8 --mem 16G --out logs/antismash.%a.log -J antismash

module unload miniconda2
module unload miniconda3
module load anaconda3
module load antismash/5.1.1
module load antismash/5.1.1
which perl
which antismash

CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
OUTDIR=/bigdata/stajichlab/shared/projects/ZyGoLife/LCG/Annotation/annotate
SAMPFILE=/bigdata/stajichlab/shared/projects/ZyGoLife/LCG/Annotation/samples2.csv
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
INPUTFOLDER=/bigdata/stajichlab/shared/projects/ZyGoLife/LCG/Annotation/annotate/predict_results

cat $SAMPFILE | sed -n ${N}p | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
	name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g; ')
 	species=$(echo "$Species" | perl -p -e "s/$Strain//")


	if [ ! -d $OUTDIR/$name ]; then
		echo "No annotation dir for ${name}"
		exit
 	fi
	if [[ ! -d $OUTDIR/$name/antismash_local && ! -s $OUTDIR/$name/antismash_local/index.html ]]; then
		antismash --taxon fungi --output-dir $OUTDIR/$name/antismash_local  --genefinding-tool none \
	    --asf --fullhmmer --cassis --clusterhmmer --asf --cb-general --pfam2go --cb-subclusters --cb-knownclusters -c $CPU \
	    $OUTDIR/$name/$INPUTFOLDER/*.gbk
	fi
done
