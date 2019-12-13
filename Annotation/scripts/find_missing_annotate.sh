#!/bin/bash
#SBATCH -p short logs/find_missing_masked.log

CPU=1

INDIR=genomes
OUTDIR=genomes
SAMPFILE=samples.csv
IFS=,
N=1
mkdir -p empty

m=$(tail -n +2 $SAMPFILE | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
 name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g')
 species=$(echo "$Species" | perl -p -e "chomp; s/$Strain//; s/\s+/_/g;")
 strain=$(echo $Strain | perl -p -e 'chomp; s/\s+/_/g')
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
	echo $N
fi
#if [ ! -s annotate/${name}/predict_misc/busco_genemark.gff3 ]; then
#	echo "rm -rf annotate/${name}/predict_misc/busco annotate/${name}/predict_misc/busco_genemark.gff3 annotate/${name}/predict_misc/busco*" >> delete_$$.sh
#	echo "mv annotate/${name}/predict_misc/EVM_busco annotate/${name}/predict_misc/EVM_busco.b" >> delete_$$.sh
#	echo $N
#fi
 N=$(expr $N + 1)
done | uniq | perl -p -e 's/\n/,/' | perl -p -e 's/,$//')

echo 'for file in annotate/*/predict_misc/EVM_busco.b; do rsync -a --delete ./empty/ $file/; rmdir $file; done' >> delete_$$.sh

#N=1
#m=$(tail -n +2 $SAMPFILE | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
#do
# name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g')
# species=$(echo "$Species" | perl -p -e "chomp; s/$Strain//; s/\s+/_/g;")
# strain=$(echo $Strain | perl -p -e 'chomp; s/\s+/_/g')
# outname="${species}_$strain"
# proteins=annotate/${name}/predict_results/$outname.proteins.fa
# if [[ -f $INDIR/${name}.sorted.fasta  && -f $OUTDIR/${name}.masked.fasta && ! -f $proteins ]]; then
#         echo $N
##	 echo "rm -rf annotate/${name}/predict_results/busco*" 1>&2
##	 echo "rm -rf annotate/${name}/predict_results/busco*" 1>&2
# fi
# N=$(expr $N + 1)
#done | perl -p -e 's/\n/,/' | perl -p -e 's/,$//')

echo "sbatch --array=$m pipeline/02_predict_optimize.sh"
