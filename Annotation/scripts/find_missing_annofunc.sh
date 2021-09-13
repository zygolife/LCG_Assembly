#!/bin/ksh
#SBATCH -p short logs/find_missing_masked.log

CPU=1

INDIR=genomes
OUTDIR=genomes
SAMPFILE=samples_prefix.csv
IFS=,
N=1
TORUN=()
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
    proteins=annotate/${name}/annotate_results/$outname.proteins.fa
    if [ ! -f $INDIR/${name}.sorted.fasta ]; then
      echo -e "\tCannot find ${name}.sorted.fasta in $INDIR - may not have been run yet ($N)" 1>&2
    elif [ ! -f $OUTDIR/${name}.masked.fasta ]; then
      echo -e "\tneed to run mask on $name ($N)" 1>&2
    elif [ ! -f $proteins ]; then
        echo -e "\tneed to run annotate on $name ($N) no $proteins" 1>&2
        TORUN+=($N)
    fi
    N=$(expr $N + 1)
done

RUNSET=$(echo -n "${TORUN[@]}" | perl -p -e 's/ /,/g')
echo "sbatch --array=$RUNSET pipeline/05_annotfunc.sh"
