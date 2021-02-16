#!/usr/bin/bash
SAMPFILE=samples.csv
IFS=,
tail -n +2 $SAMPFILE | while read ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
	name=$(echo "$Species" | perl -p -e 'chomp; s/\s+/_/g; ')
	fixedname=$(echo $name | perl -p -e 's/\+/_Plus/; s/PlusT/Plus-T/')
#	echo "$name -> $fixedname"
	if [ ! -e genomes/$fixedname.sorted.fasta ]; then
		if [ -f ../Assembly/genomes/$name.sorted.fasta ] ; then
			ln -s ../../Assembly/genomes/$name.sorted.fasta genomes/$fixedname.sorted.fasta
		else
			echo "../Assembly/genomes/$name.sorted.fasta not present, is assembly AAFTF run finished?"
		fi
	fi
done
