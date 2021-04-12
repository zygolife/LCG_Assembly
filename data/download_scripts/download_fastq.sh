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
 n="$n.$JGIProjName"
 #echo "n is $n Species is $Species barcode is $JGIBarcode"
 #grep $JGIBarcode $XML | grep filter-

 URL=$(grep $JGIBarcode $XML | grep filter- | perl -p -e 's/\n/,/g; s/.+\s+url=\"([^\"]+)\".+/$1/; s/\/ext-api\S+url=//')
# echo $URL
 if [ ! -z "$URL" ];  then
  echo $URL | while read url
  do
     #echo "$JGIBarcode '$url' $n"
     if [ ! -s $ODIR/$n.fastq.gz ]; then
    	 echo "DOWNLOADURL:'$HOST$url' $n.fastq.gz $ODIR/$n.fastq.gz  -- filter-FUNGAL"
	 echo "curl -o $ODIR/$n.fastq.gz \"$HOST$url\" -b cookies"

	 curl -o $ODIR/$n.fastq.gz "$HOST$url" -b cookies
     fi
     if [ ! -s $ODIR/$n.fastq.gz ]; then
	echo "Failed to download $n $Species $JGIBarcode"
     fi
     continue
 done
 fi
 url=$(grep $JGIBarcode\.anqdpht.fastq.gz $XML | perl -p -e 's/.+\s+url=\"([^"]+)\".+/$1/; s/\/ext-api\S+url=//')
 if [ ! -z "$url" ]; then
     echo "$JGIBarcode $url $n"
     echo "$HOST$url"
     if [ ! -s $ODIR/$n.fastq.gz ]; then
	 echo "DOWNLOADURL:'$HOST$url' $n.fastq.gz $ODIR/$n.fastq.gz -- anqdpht"
	 curl -o $ODIR/$n.fastq.gz "$HOST$url" -b cookies
     fi
     continue
 fi

# exit
done
