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
 echo "n is $n Species is $Species barcode is $JGIBarcode"
 grep $JGIBarcode $XML | grep filter-

 url=$(grep $JGIBarcode $XML | grep filter- | perl -p -e 's/.+\s+url=\"([^"]+)\".+/$1/; s/\/ext-api\S+url=//')
 if [ $url ];  then
     echo "$JGIBarcode $url $n"
     if [ ! -s $ODIR/$n.fastq.gz ]; then
    	 echo "$HOST$url $n.fastq.gz $ODIR/$n.fastq.gz  -- filter-FUNGAL"
	 curl "$HOST$url" -b cookies > $ODIR/$n.fastq.gz
     fi
     if [ ! -s $ODIR/$n.fastq.gz ]; then
	echo "did not download $n $Species $JGIBarcode"
     fi
     continue
 fi
 url=$(grep $JGIBarcode\.anqdpht.fastq.gz $XML | perl -p -e 's/.+\s+url=\"([^"]+)\".+/$1/; s/\/ext-api\S+url=//')
 if [ ! -z $url ]; then
     echo "$JGIBarcode $url $n"
     echo "$HOST$url"
     if [ ! -s $ODIR/$n.fastq.gz ]; then
	 echo "$HOST$url $n.fastq.gz $ODIR/$n.fastq.gz -- anqdpht"
	 curl "$HOST$url" -b cookies > $ODIR/$n.fastq.gz
     fi
     continue
 fi

# exit
done
