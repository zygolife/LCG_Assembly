#!/usr/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=16 --mem 48gb
#SBATCH --output=logs/annotfunc.%a.log
#SBATCH --time=2-0:00:00
#SBATCH -p intel,batch -J annotfunc
module unload miniconda3
module load funannotate
module load phobius
OUTDIR=annotate
BUSCO=/srv/projects/db/BUSCO/v10/lineages/fungi_odb10

if [ -z $SLURM_CPUS_ON_NODE ]; then
	CPUS=1
else
 CPUS=$SLURM_CPUS_ON_NODE
fi

INDIR=genomes
OUTDIR=annotate
SAMPFILE=samples_prefix.csv

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
    species=$(echo -n "$SPECIES" | perl -p -e "s/\s*\Q$STRAIN\E//; chomp;")
    MOREFEATURE=""
    TEMPLATE=$(realpath submit_files/${name}.sbt)
    if [ ! -f $TEMPLATE ]; then
	echo "NO TEMPLATE for $name (no file $TEMPLATE)"
	exit
    fi
    # need to add detect for antismash and then add that

    #LOCUSTAG=$(python scripts/get_locus.py $name)
    #if [ -z $LOCUSTAG ]; then
    #	echo " no LOCUSTAG for $Species"
    #	#exit
    #fi
    ANTISMASHSTAGE=$OUTDIR/$name/annotate_misc/antiSMASH.results.gbk
    ANTISMASHRUN=$OUTDIR/$name/antismash_local/$name.gbk

    echo "$name $species $STRAIN"
    if [[ -f $ANTISMASHRUN ]]; then
	rsync -a $ANTISMASHRUN $ANTISMASHSTAGE
    fi
    if [ -z $LOCUSTAG ]; then
	echo "cannot find locus for $name"
	funannotate annotate --sbt $TEMPLATE --busco_db $BUSCO -i $OUTDIR/$name --species "$species" --strain "$STRAIN" --cpus $CPUS
    else
	echo "will rename genes to $LOCUSTAG"
	funannotate annotate --sbt $TEMPLATE --busco_db $BUSCO -i $OUTDIR/$name --species "$species" --strain "$STRAIN" --rename $LOCUSTAG --cpus $CPUS
    fi
done
