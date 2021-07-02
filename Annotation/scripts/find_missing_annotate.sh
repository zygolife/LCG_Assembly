#!/bin/ksh
#SBATCH -p short logs/find_missing_masked.log

CPU=1

INDIR=genomes
OUTDIR=genomes
SAMPFILE=samples_prefix.csv
IFS=,
N=1
mkdir -p empty
TORUN=()
tail -n +2 $SAMPFILE | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
do
    name=$(echo "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g')
#    echo "SP=$SPECIES strain=$STRAIN"
    species=$(echo "$SPECIES" | perl -p -e "s/\Q$STRAIN\E//; s/\s+/_/g;")
    strain=$(echo $STRAIN | perl -p -e 'chomp; s/\s+/_/g')
    if [ ! -z $strain ]; then
	outname="${species}_$strain"
    else
	outname="${species}"
    fi
    proteins=annotate/${name}/predict_results/$outname.proteins.fa
    if [ ! -f $INDIR/${name}.sorted.fasta ]; then
	echo -e "\tCannot find ${name}.sorted.fasta in $INDIR - may not have been run yet ($N)" 1>&2
    elif [ ! -f $OUTDIR/${name}.masked.fasta ]; then
	echo "need to run mask on $name ($N)" 1>&2
    elif [ ! -f $proteins ]; then
        echo "need to run annotate on $name ($N) no $proteins" 1>&2
	if [ ! -s annotate/${name}/predict_results/augustus.gff3 ]; then
	    echo "echo annotate/${name}" >>  delete_$$.sh
	    echo "/usr/bin/rm -rf annotate/${name}/predict_misc/busco*" >> delete_$$.sh
	    echo "mv annotate/${name}/predict_misc/EVM_busco annotate/${name}/predict_misc/EVM_busco.b" >> delete_$$.sh
	    echo "/usr/bin/rm -rf annotate/${name}/predict_misc/hints.*" >> delete_$$.sh
	fi
	if [ ! -s annotate/${name}/predict_misc/genemark/genemark.gtf ]; then
		 echo "rm -rf annotate/${name}/predict_misc/genemark*" >> delete_$$.sh
	fi
	TORUN+=($N)	
    fi
    N=$(expr $N + 1)
done

echo 'for file in annotate/*/predict_misc/EVM_busco.b; do rsync -a --delete ./empty/ $file/; rmdir $file; done' >> delete_$$.sh
RUNSET=$(echo "${TORUN[@]}" | perl -p -e 's/ /,/g')

echo "sbatch --array=$RUNSET pipeline/02_predict_optimize.sh"
