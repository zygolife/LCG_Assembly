n=1
while read strain domain; do 
	if [[ ! -f genomes/$strain.spades.fasta && ! -f genomes/$strain.spades.fasta.gz && ! -f genomes/$strain.sorted.fasta ]]; then echo "$n $strain"; fi; 
	n=$(expr $n + 1);
done < samples.dat
n=1
m=$(while read strain domain; do 
if [[ ! -e genomes/$strain.spades.fasta && ! -e genomes/$strain.spades.fasta.gz && ! -e genomes/$strain.sorted.fasta ]]; then   echo "$n"; fi; 
n=$(expr $n + 1); 
done < samples.dat | perl -p -e 's/\n/,/' | perl -p -e 's/,$//')
echo "sbatch --array=$m pipeline/02_AAFTF.sh"
