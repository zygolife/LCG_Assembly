#!/bin/ksh
#SBATCH -p short logs/find_missing_genemark.log

CPU=1

INDIR=genomes
SAMPFILE=samples_prefix.csv
IFS=,
N=1
TORUN=()
ODIR=annotate
N=1
tail -n +2 $SAMPFILE | while read SPECIES PHYLUM STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE KEEPLCG DEPOSITASM
do
	name=$(echo -n "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g')
#    echo "SP=$SPECIES strain=$STRAIN"
	species=$(echo -n "$SPECIES" | perl -p -e "s/\Q$STRAIN\E//; chomp; s/\s+/_/g; s/_$//;")
	strain=$(echo -n $STRAIN | perl -p -e 'chomp; s/\s+/_/g')
	if [ ! -z $strain ]; then
		outname="${species}_$strain"
	else
		outname="${species}"
	fi

	if [[ ! -f "$ODIR/$name/predict_misc/genemark/output/gmhmm.mod" &&
		! -f "$ODIR/$name/predict_misc/gmhmm.mod" ]]; then
			echo "No genemark in $name"
		TORUN+=($N)
	elif [[ ! -f "$ODIR/$name/predict_misc/genemark.gff" ]]; then
		TORUN+=($N)
	fi
	N=$(expr $N + 1)
done
RUNSET=$(echo -n "${TORUN[@]}" | perl -p -e 's/ /,/g')
echo "sbatch --array=$RUNSET pipeline/01_genemark.sh"
