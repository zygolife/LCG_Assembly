#!/bin/bash
#SBATCH -p short --out logs/find_missing_anofunc.log

CPU=1

INDIR=genomes
OUTDIR=genomes
SAMPFILE=samples.csv
IFS=,
N=1
mkdir -p empty

m=$(cat $SAMPFILE | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
 name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g')
 species=$(echo "$Species" | perl -p -e "chomp; s/$Strain//; s/\s+/_/g;")
 strain=$(echo $Strain | perl -p -e 'chomp; s/\s+/_/g')
 if [ ! -z $strain ]; then
 	outname="${species}_$strain"
 else
	 outname="${species}"
 fi
 ipr=annotate/${name}/annotate_misc/iprscan.xml
 if [ ! -f $INDIR/${name}.sorted.fasta ]; then
    echo -e "\tCannot find ${name}.sorted.fasta in $INDIR - may not have been run yet ($N)" 1>&2
 elif [ ! -f $OUTDIR/${name}.masked.fasta ]; then
	echo "need to run mask on $name ($N)" 1>&2
 elif [ ! -f $ipr ]; then
        echo "need to run annotateifunc on $name ($N) no $ipr " 1>&2
	echo $N
fi
 N=$(expr $N + 1)
done | uniq | perl -p -e 's/\n/,/' | perl -p -e 's/,$//')

echo "sbatch --array=$m pipeline/05b_iprscan.sh"
