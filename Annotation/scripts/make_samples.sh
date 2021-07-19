#!/usr/bin/bash
for a in $(ls ../data/1978*.csv ../data/UFL.csv ../data/UCR.csv);
do
	tail -n +2 $a | grep -v -P -i "skip|Contam|too low" | grep -v Chytridiomycota | grep -v Blastocladiomycota
done > samples.new.csv
(head -n 1 samples.new.csv && tail -n +2 samples.new.csv | sort -t, -k5,6 ) > samples.new2.csv
perl -p -e 's/\r\n/\n/g; s/\+/_Plus/g; s/PlusT/Plus-T/g' samples.new2.csv > samples.new.csv
#mv samples.new2.csv samples.new.csv
