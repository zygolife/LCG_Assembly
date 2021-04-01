n=1
cut -f1 samples.dat | while read strain; do 
	if [ ! -d BUSCO/${strain} ]; then echo "$n $strain"; fi; 
	n=$(expr $n + 1);
done
n=1
m=$(cut -f1 samples.dat | while read strain; do 
if [ ! -d BUSCO/${strain} ]; then echo "$n"; fi; 
n=$(expr $n + 1); 
done | perl -p -e 's/\n/,/' | perl -p -e 's/,$//')
echo "sbatch --array=$m pipeline/03_BUSCO.sh"

