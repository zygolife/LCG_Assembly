#!/usr/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=16 --mem 16gb
#SBATCH --output=logs/annotfunc.%a.log
#SBATCH --time=2-0:00:00
#SBATCH -p intel -J annotfunc
module unload miniconda3
module load funannotate
module load phobius
CPUS=$SLURM_CPUS_ON_NODE
OUTDIR=annotate
SAMPFILE=samples.csv
BUSCO=/srv/projects/db/BUSCO/v10/lineages/fungi_odb10
if [ ! $CPUS ]; then
 CPUS=1
fi
N=${SLURM_ARRAY_TASK_ID}
INDIR=genomes
OUTDIR=annotate

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
	MOREFEATURE=""
	TEMPLATE=$(realpath submit_files/${name}.sbt)
	if [ ! -f $TEMPLATE ]; then
		echo "NO TEMPLATE for $name"
		exit
	fi
	# need to add detect for antismash and then add that
	LOCUSTAG=$(python scripts/get_locus.py $name)
	if [ -z $LOCUSTAG ]; then
		echo " no LOCUSTAG for $Species"
		#exit
	fi
	ANTISMASHRESULT=$OUTDIR/$name/annotate_misc/antiSMASH.results.gbk
	echo "$name $species"
	if [[ ! -f $ANTISMASHRESULT && -d $OUTDIR/$name/antismash_local ]]; then
		ANTISMASH=$(ls $OUTDIR/$name/antismash_local/*__*.gbk | awk '{print $1}')
		rsync -a $ANTISMASH $ANTISMASHRESULT
	fi
	if [ -z $LOCUSTAG ]; then
		echo "cannot find locus for $name"
		funannotate annotate --sbt $TEMPLATE --busco_db $BUSCO -i $OUTDIR/$name --species "$species" --strain "$Strain" --cpus $CPUS
	else
		echo "will rename genes to $LOCUSTAG"
		funannotate annotate --sbt $TEMPLATE --busco_db $BUSCO -i $OUTDIR/$name --species "$species" --strain "$Strain" --rename $LOCUSTAG --cpus $CPUS 
	fi

done
