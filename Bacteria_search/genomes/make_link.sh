#!/usr/bin/bash

for dir in ../asm/*.spades
do
	b=$(basename $dir)
	if [[ ! -L $b.fasta && -f $dir/scaffolds.fasta ]]; then
		ln -s $dir/scaffolds.fasta $b.fasta
	fi
done

for dir in ../asm/*.metaspades
do
        b=$(basename $dir)
	if [[ ! -L $b.fasta && -f $dir/scaffolds.fasta ]]; then
        	ln -s $dir/scaffolds.fasta $b.fasta
	fi
done

