#!/bin/ksh
#SBATCH -p short --out logs/find_missing_anofunc.log

INDIR=genomes
OUTDIR=annotate
SAMPFILE=samples_prefix.csv
N=1
IFS=,
TORUN=()
tail -n +2 $SAMPFILE | while read SPECIES PHYLUM STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE KEEPLCG DEPOSITASM
do
    name=$(echo "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g')
    species=$(echo "$SPECIES" | perl -p -e "s/\Q$STRAIN\E//")
    ipr=$OUTDIR/$name/annotate_misc/iprscan.xml

    if [ ! -f $INDIR/${name}.sorted.fasta ]; then
	     echo -e "\tCannot find $INDIR/${name}.sorted.fasta in $INDIR - may not have been run yet ($N)" 1>&2
    elif [ ! -f $INDIR/${name}.masked.fasta ]; then
	     echo "need to run mask on $name ($N)" 1>&2
    elif [ ! -f $ipr ]; then
        echo "need to run annotate func on $name ($N) no $ipr " 1>&2
	      TORUN+=($N)
    fi
    N=$(expr $N + 1)
done
m=$(echo -n "${TORUN[@]}" | perl -p -e 's/ /,/g')
echo "sbatch --array=$m pipeline/04_iprscan.sh"
