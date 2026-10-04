# ZyGoLife LCG genomes: cleanup, deposit and release plan

Date: 2026-10-04. Status: draft for review. Nothing has been submitted to NCBI.

## Goal
Publish the ZyGoLife low-coverage genome (LCG) set: every genome with a
correct name, its raw reads in SRA, and its assembly with a current annotation
in GenBank, released with the LCG paper.

## Sources
- Sample sheet: `Annotation/samples_prefix.csv` (895 rows; shared folder
  `/bigdata/stajichlab/shared/projects/ZyGoLife/LCG`). Columns used: SPECIES,
  STRAIN, BIOSAMPLE, BIOPROJECT, TAXONOMY_ID, ORGANISM_NAME_NCBI_LOOKUP,
  SRA_RUNID, LOCUSTAG, "Keep in LCG Paper", "Deposit in NCBI".
- Local data (shared folder): reads `Assembly/input/<stem>_R1/R2.fq.gz`,
  assemblies `Assembly/genomes/<stem>.sorted.fasta`, annotations
  `Annotation/annotate/<stem>/annotate_results/` (funannotate, with `.sqn`).
  `<stem>` = SPECIES with spaces replaced by `_`.
- Name checks from MATPredict (github.com/stajichlab/MATPredict):
  `db/taxon_overrides.tsv` (genomes whose deposited name is likely wrong) and
  the B12 BUSCO-tree name check (`results/2026-10-01_lcg_name_check/flags.tsv`,
  rDNA check in `its_check/`), plus MAT-locus calls for 621 Mucoromycotina LCG
  genomes.

## Current state (measured 2026-10-04; `deposit/inventory.py` -> `deposit/inventory.tsv`, `deposit/inventory_summary.txt`)
NCBI columns use public records only (E-utilities); a private record counts as
"not found".

| | Count |
|---|---|
| Rows | 895 (Mucoromycotina 627, Kickxellomycotina 172, Mortierellomycotina 78, Entomophthoromycotina 18) |
| Keep in LCG Paper: Yes / No / ? | 815 / 79 / 1 (all 79 "No" are also "Deposit: No") |
| Deposit in NCBI: Yes / Already / No / ? | 752 / 63 / 79 / 1 |
| BioSample public | 870 (25 blank or not public; 20 blank) |
| SRA run public for the BioSample | 866 (29 not found; 27 have local reads) |
| Genome assembly at NCBI | 249 (all annotated; dates 2017-2024, most 2020 and 2023) |
| Deposit = Yes and no assembly at NCBI | **565** (Mucoromycotina 536, Entomophthoromycotina 17, Mortierellomycotina 11, Kickxellomycotina 1) |
| Local: reads / assembly / `.sqn` | 881 / 880 / 812 |
| Missing locus tag / taxid in the sheet | 23 / 47 |

Of the 565 still to deposit: 551 have a local assembly, 554 a local `.sqn`;
22 have no public BioSample; 25 no public SRA run; 20 no locus tag; 17 no
taxid; 17 carry a MATPredict override; 95 carry a B12 genus flag.

Sheet inconsistencies:
- "No" but an assembly is public: Mycoemilia scoparia NBRC 100468, Mycotypha
  africana NRRL 2978.
- "Already" but no public assembly found: Lobosporangium transversale NRRL 3116,
  Mortierella parvispora AD039, Mortierella polygonia AM948.
- "?": Rhizopus arrhizus NRRL A-23526.
- One BioSample on two rows (SAMN11510657).
- 114 rows where the SPECIES genus differs from the NCBI organism name (many are
  later renames, e.g. Mortierella -> Entomortierella, Linnemannia; others may
  be misidentifications).

## Findings from MATPredict that change names or deposit decisions
- 18 genomes have a taxon override (19 after MATPredict PR #21: Mucor sp.
  NRRL 1454 -> Umbelopsis sp.). 13 are confirmed at genus rank by BUSCO trees
  and rDNA; the rest are unconfirmed (locus genes only, or rDNA and markers
  disagree: Circinella muscae NRRL 1360, a possible mixed sample).
- Two genomes are held out as a possible sample mixup or contamination:
  Pilaira anomala RSA 1997 "Plus" (is Cunninghamella) and Thamnidium elegans
  NRRL 2467 (is Syncephalastrum). **NRRL 2467 already has a public assembly
  under the T. elegans name.**
- 102 genomes carry a B12 genus flag (`flags.tsv`: the BUSCO tree places them
  away from their file-name genus). An IQ-TREE subtree held 75 of 101 FastTree
  flags at UFBoot >= 95. Only the 13 distant-genus ones (and NRRL 1454) were
  rDNA-checked.
- 4 public reference genomes (not LCG) carry foreign rDNA; noted, not an LCG
  action.
- Mating-type labels in strain names are wrong for several strains (e.g. RSA
  1997 "Plus" carries sexM). The file names are not changed; the label should
  not be carried into the organism or strain name at NCBI.

## Plan

### Phase 0: freeze and fix the sample sheet
1. Make one authoritative sheet, `deposit/lcg_master.tsv`, from
   `samples_prefix.csv` + `inventory.tsv`; never edit the inventory by hand.
2. Resolve the inconsistencies above (flags, the duplicate BioSample, "?").
3. Fill the 47 missing taxids and 23 missing locus tags (locus-tag prefixes
   must be registered to the BioProject that the BioSample belongs to).

### Phase 1: final names (classification)
For each genome decide the submission organism name, using in order:
1. curator ruling / confirmed override (genus rank -> "<Genus> sp. <strain>");
2. B12 flag with high support (UFBoot >= 95) and rDNA agreement -> rename;
3. B12 flag without rDNA check -> rDNA check first (same method as the 13);
4. NCBI taxonomy rename of the named species (accept the current NCBI name).
Hold out (do not deposit) genomes with a possible mixup until resolved. For the
already-public T. elegans NRRL 2467, decide whether to ask NCBI to correct the
organism or suppress the record.

### Phase 2: raw reads (all deposited)
Recommendation: yes, the reads of every deposited genome go to SRA (the paper's
data policy will need them; who submitted the existing runs was not checked).
866 already have a public SRA run for their BioSample. Steps:
1. Check each public run belongs to the sheet's BioSample and strain (run
   metadata vs sheet).
2. Submit the 29 without a public run: 27 have local reads; locate the reads
   for the other 2. The 25 rows without a public BioSample need a BioSample
   first.
3. Reads for the 79 "Keep: No" genomes: deposit only if the sample is valid
   (not a failed or contaminated library) — curator decision.

### Phase 3: re-annotation (funannotate 1.9.0-rc.6 via nf_funannotate1)
The local annotations are from earlier funannotate versions. Re-annotate with
funannotate 1.9.0-rc.6 using `stajichlab/nf_funannotate1`
(`/bigdata/stajichlab/jstajich/projects/nf/nf_funannotate1`; samplesheet
columns SPECIES, STRAIN, ASMID, LOCUSTAG, BUSCO_LINEAGE, TRANSL_TABLE,
NCBI_TAXONID, GENOME).
1. Build the nf_funannotate1 samplesheet from `lcg_master.tsv` with the
   Phase 1 names, registered locus tags and BUSCO lineages
   (mucoromycota_odb12 etc.).
2. Contamination screen with NCBI FCS-GX before submission: NCBI screens new
   genome submissions for contamination, so screening first avoids returned
   submissions. `nf_funannotate1` does this in its GENOME_CLEAN step (AAFTF +
   FCS-GX purge; on by default, `--skip_fcs true` turns it off; needs the
   ~470 GB FCS-GX database, highmem queue on UCR HPCC).
3. Order: the 565 to deposit first (Mucoromycotina 536), then the 249
   already public if their annotation is to be updated (decision below).
4. QC per genome: BUSCO completeness, gene count, table2asn error report.

### Phase 4: genome submission
1. Batch WGS submissions (Genome Submission Portal) per BioProject, using the
   table2asn `.sqn` from nf_funannotate1, with FCS-GX results.
2. Start with a pilot batch of about 10 genomes from different orders; fix
   validation issues; then batches of about 50.
3. Track every submission (SUB id, accession, status) in `deposit/submissions.tsv`.

### Phase 5: release
Hold-until-publication or immediate release (decision below); update the
sheet with GCA accessions; link the BioProjects to an umbrella project.

## Decisions needed
1. Release timing: at submission, or hold until the LCG paper.
2. Re-annotate and update the 249 genomes already public, or leave them.
3. Deposit reads (and genomes) for the 79 "Keep: No" samples?
4. Organism-name policy for B12 flags without rDNA checks (rename, check, or
   keep the deposited name with a note).
5. Thamnidium elegans NRRL 2467 (public, possible mixup): correct, suppress,
   or leave with a note.
6. One umbrella BioProject for the paper.

## Next steps (in order)
1. Review this plan; answer the decisions.
2. Phase 0 sheet cleanup (`lcg_master.tsv`).
3. rDNA check for the B12 flags not yet checked; finalize names (Phase 1).
4. Submit the 29 missing read sets (Phase 2).
5. Pilot re-annotation of 10 genomes with nf_funannotate1 rc.6, then the 565.
6. Pilot genome submission, then batches.
