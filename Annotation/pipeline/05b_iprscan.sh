#!/bin/bash
#SBATCH --ntasks 24 --nodes 1 --mem 96G -p intel 
#SBATCH --time 72:00:00 --out logs/iprscan.%a.log
module unload miniconda2
module unload miniconda3
module load anaconda3
module load funannotate/development
module unload perl
module unload python
source activate funannotate
module load iprscan
module unload perl
CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
# let's pick this more hard-codeed based on the number of embeded workers that will run
SPLIT_CPU=5
OUTDIR=annotate
SAMPFILE=samples.csv
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
cat $SAMPFILE | sed -n ${N}p | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
	name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g; ')
 	species=$(echo "$Species" | perl -p -e "s/$Strain//")

	 if [ ! -d $OUTDIR/$name ]; then
		echo "No annotation dir for ${name}"
		exit
 	fi
	mkdir -p $OUTDIR/$name/annotate_misc
	XML=$OUTDIR/$name/annotate_misc/iprscan.xml
	IPRPATH=$(which interproscan.sh)
	if [ ! -f $XML ]; then
	    funannotate iprscan -i $OUTDIR/$name -o $XML -m local -c $SPLIT_CPU --iprscan_path $IPRPATH -n 100
	fi
done
