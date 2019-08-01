#!/usr/bin/bash

dat=data/UFL.csv
OUTDIR=input
INDIR=data/UFL

IFS=,

tail -n +2 $dat | while read ProjID Sample ProjName Barcode SubPhyla Species Strain Notes
do
    outname=$(echo "$Species" | perl -p -e 's/ /_/g')
    for DIR in 1 2
    do
	ln -s ../$INDIR/${ProjName}_${DIR}.fq.gz $OUTDIR/${outname}_R${DIR}.fq.gz
    done
done
