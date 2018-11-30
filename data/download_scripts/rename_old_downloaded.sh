#!/bin/bash

SAMPLES=$1

# expect a sample file as cmdline
if [ ! -f $SAMPLES ]; then
	echo "NEED a sample CSV file as cmdline"
fi
XML=Genofbecologies.xml
HOST=https://genome.jgi.doe.gov
ODIR=$(basename $SAMPLES .csv)
mkdir -p $ODIR
IFS=","
tail -n +2 $SAMPLES | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Notes
do
 n=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g') 
 if [ ! -e $ODIR/$n.fastq.gz ]; then
 	if [ -f ${ODIR}_old/$JGIBarcode.anqdpht.fastq.gz ]; then
		rsync -av ${ODIR}_old/$JGIBarcode.anqdpht.fastq.gz $ODIR/$n.fastq.gz
 	fi
 fi
done
