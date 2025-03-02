include { MEGAHIT                   } from '../modules/megahit'
include { METASPADES                } from '../modules/metaspades'
include { CHOOSE_BEST_REF           } from '../modules/choose_best_ref'
include { MUMMER                    } from '../modules/mummer'
include { FILTER_AND_GLUE_CONTIGS   } from '../modules/filter_and_glue_contigs'
include { GAPFILL_WITH_READS        } from '../modules/gapfill_with_reads'
include { GAPFILL_WITH_REF          } from '../modules/gapfill_with_ref'

workflow CONTIG_GEN {

   take: 
   reads_meta       // tuple val(meta), path(reads)
   contig_method    // val(contig_method)
   ref_ch           // path(ref)

   main:

   if (contig_method == "megahit") {
       MEGAHIT(reads_meta)
    contigs = MEGAHIT.out.contigs

   } 
   else if (contig_method == "metaspades") {
       METASPADES(reads_meta)
    contigs = METASPADES.out.contigs
   }

   else {
    // this should be checked beforehand in main.nf, but leaving it here for completion's sake
    throw new IllegalArgumentException("Invalid contig method: ${contig_method}. Choose from 'metaspades' or 'megahit'")
   }

   CHOOSE_BEST_REF(
    contigs,
    ref_ch
   )

   CHOOSE_BEST_REF.out.ref_name
   .map {meta, ref_file-> def ref_name = ref_file.text.trim() 
   return [meta, ref_name] }
   .set { ref_name_ch }
   
   CHOOSE_BEST_REF.out.chosen_ref.join(ref_name_ch)
   .set { contig_prep_ch }

   MUMMER(contig_prep_ch)

   FILTER_AND_GLUE_CONTIGS(
    MUMMER.out.delta_tile
   )

   GAPFILL_WITH_READS(
    FILTER_AND_GLUE_CONTIGS
    .out.intermediate_scaffold
    .join(reads_meta, by: [0])
   )

   GAPFILL_WITH_REF(
    GAPFILL_WITH_READS.out.gapfilled_scaffold
   )

   emit: 
   contigs = GAPFILL_WITH_REF.out.prep_scaffold

}
