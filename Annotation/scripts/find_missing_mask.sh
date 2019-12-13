#!/bin/bash
#SBATCH -p short logs/find_missing_masked.log

CPU=1

INDIR=genomes
OUTDIR=genomes
LIBRARY=lib/zygo_repeats.fasta
SAMPFILE=samples.csv
IFS=,
N=1
tail -n +2 $SAMPFILE | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
 name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g')
 species=$(echo "$Species" | perl -p -e "s/$Strain//")
 echo "$name"
 if [ ! -f $INDIR/${name}.sorted.fasta ]; then
    echo -e "\tCannot find $name.sorted.fasta in $INDIR - may not have been run yet ($N)"
 elif [ ! -f $OUTDIR/${name}.masked.fasta ]; then
	 echo "need to run $name ($N)"
 fi
 N=$(expr $N + 1)
done

N=1

m=$(tail -n +2 $SAMPFILE | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
 name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g')
 if [[ -f $INDIR/${name}.sorted.fasta  && ! -f $OUTDIR/${name}.masked.fasta ]]; then
         echo $N
 fi
 N=$(expr $N + 1)
done | perl -p -e 's/\n/,/' | perl -p -e 's/,$//')

echo "sbatch --array=$m pipeline/00_mask.sh"
