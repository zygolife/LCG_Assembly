#!/usr/bin/bash
SAMPFILE=samples_prefix.csv
IFS=,
BASEFOLDER=/bigdata/stajichlab/shared/projects/ZyGoLife/LCG/Assembly/genomes
tail -n +2 $SAMPFILE | while read SPECIES STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE
#ProjID JGISample JGIProjName JGIBarcode SubPhyla Species Strain Note
do
	fixedname=$(echo "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g; ')
	name=$(echo $fixedname | perl -p -e 's/_Plus-T/+T/; s/_Plus/+/')
#	echo "$name -> $fixedname"
	if [ ! -e genomes/$fixedname.sorted.fasta ]; then
		if [ -f $BASEFOLDER/$name.sorted.fasta ] ; then
			ln -s $BASEFOLDER/$name.sorted.fasta genomes/$fixedname.sorted.fasta
		else
			echo "$BASEFOLDER/$name.sorted.fasta not present, is assembly AAFTF run finished?"
		fi
	fi
done
