#!/usr/bin/bash -l

for d in $(ls -d annotate/*/predict_results)
do
    for f in $(ls $d/*__*.gff3)
    do
	new=$(echo $f | perl -p -e 's/__/_/')
	t=$(basename $f)
	ln -s $t $new
    done

    for f in $(ls $d/*__*.proteins.fa)
    do
	new=$(echo $f | perl -p -e 's/__/_/')
	t=$(basename $f)
	ln -s $t $new
    done

    for f in $(ls $d/*__*.cds-transcripts.fa)
    do
	new=$(echo $f | perl -p -e 's/__/_/')
	t=$(basename $f)
	ln -s $t $new
    done    
done
