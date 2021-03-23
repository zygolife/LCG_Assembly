for a in $(ls shovill_*/contigs.fa); do d=$(dirname $a); d=$(echo $d | perl -p -e 's/shovill_//'); rsync -av $a ../genomes/$d.spades.fasta; done
