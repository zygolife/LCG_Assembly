#!/usr/bin/bash

for file in 1978*.csv
do
  ODIR=$(basename $file .csv)
  IFS=,
  tail -n +2 $file | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Notes
  do
      n=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g')
      if [ ! -e $ODIR/$n.fastq.gz ]; then
	  echo "Plate: $file - Missing $ODIR/$n.fastq.gz ($n $JGIProjName)"
      fi
  done
done
