# Handoff: LCG cleanup and deposit (2026-10-04)

Read `PLAN.md` first. This file says where things are and what to do next.

## What exists
- `deposit/inventory.py`: rebuilds `inventory.tsv` (one row per sample-sheet
  row: local reads/assembly/annotation, public BioSample/SRA/assembly at NCBI,
  MATPredict override and B12 flag). Run time about 2 min; no NCBI e-mail
  sent; `NCBI_API_KEY` speeds it up.
- `deposit/inventory.tsv`, `deposit/inventory_summary.txt`: the 2026-10-04 run.
- `deposit/PLAN.md`: state, findings, phases, decisions.

## Where the data and related work are
- Shared LCG folder (data, sample sheets, old annotations):
  `/bigdata/stajichlab/shared/projects/ZyGoLife/LCG`. Its git checkout has
  other people's uncommitted changes; do not commit from it. Work in a clone.
- Sample sheet: `Annotation/samples_prefix.csv` (same as
  `Annotation_2026/samples.csv`).
- MATPredict (name checks, overrides, MAT calls):
  `/bigdata/stajichlab/jstajich/projects/MATPredict`; overrides in
  `db/taxon_overrides.tsv` (18 on main, 19 with PR #21); B12 name check in
  `results/2026-10-01_lcg_name_check/` (`flags.tsv`, `its_check/NOTE.md`,
  `iqtree_subtree/`); reports in `analysis/2026-10-02_lcg-overrides-manual-review.md`
  and `ANNOTATION_ERRORS_FIXED_REPORT.md` (C5-C7, C12, C13).
- Re-annotation pipeline: `stajichlab/nf_funannotate1`
  (`/bigdata/stajichlab/jstajich/projects/nf/nf_funannotate1`), target
  funannotate 1.9.0-rc.6 (the conda config currently pins rc.5; check the
  container/env for rc.6 before the pilot).

## Next steps
1. Curator answers the six decisions in `PLAN.md`.
2. Phase 0: build `deposit/lcg_master.tsv`; fix flags, duplicate BioSample
   SAMN11510657, the "?" row, 47 missing taxids, 23 missing locus tags.
3. Phase 1: rDNA check for B12 flags not yet checked (method:
   MATPredict `results/2026-10-01_lcg_name_check/its_check/extract_one.sh`);
   final organism names.
4. Phase 2: SRA for the 29 genomes without a public run.
5. Phase 3: nf_funannotate1 rc.6 pilot (10 genomes, mixed orders), then the 565.
6. Phase 4: pilot genome submission, then batches; track in `submissions.tsv`.

## Cautions
- NCBI "not found" means not public; private or embargoed records look the same.
- Held out (possible mixup; do not deposit until resolved): Pilaira anomala
  RSA 1997 "Plus", Thamnidium elegans NRRL 2467 (already public under that name).
- File names keep their original (sometimes wrong) names and mating-type labels;
  do not copy those labels into NCBI organism or strain fields.
