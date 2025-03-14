//  check args
if (params.input) { ch_input = file(params.input) } else { exit 1, 'No samplesheet specified!' }
if (!params.refs || !file(params.refs).exists()) { exit 1, "Invalid path specified: reference genome multifasta (--ref) " }
if (!params.kraken2_db || !file(params.kraken2_db).exists()) {exit 1, "Invalid path specified: kraken2 database (--kraken2_db)" }
if (!params.taxids || !file(params.taxids).exists()) {exit 1, "Invalid path specified: taxon ID TSV (--taxids)" }

// Import subworkflows
include { INPUT_CHECK           } from './subworkflows/input_check'
include { FASTP_MULTIQC         } from './subworkflows/fastp_multiqc'
include { PROFILE_READS         } from './subworkflows/profile_reads'
include { CONTIG_GEN            } from './subworkflows/contig_gen'
include { CONSENSUS_ASSEMBLY    } from './subworkflows/consensus_assembly'

// Import modules
include { KRAKEN2           } from './modules/kraken2'
include { SUBSAMPLE_FASTQ   } from './modules/subsample'

log.info("   █████████   ██████████     █████████   ███████████      ") 
log.info("  ███░░░░░███ ░░███░░░░███   ███░░░░░███ ░░███░░░░░███     ") 
log.info(" ░███    ░███  ░███   ░░███ ░███    ░███  ░███    ░███     ") 
log.info(" ░███████████  ░███    ░███ ░███████████  ░██████████      ") 
log.info(" ░███░░░░░███  ░███    ░███ ░███░░░░░███  ░███░░░░░███     ")
log.info(" ░███    ░███  ░███    ███  ░███    ░███  ░███    ░███     ")
log.info(" █████   █████ ██████████   █████   █████ █████   █████    ")
log.info("░░░░░   ░░░░░ ░░░░░░░░░░   ░░░░░   ░░░░░ ░░░░░   ░░░░░     ") 
log.info "Assisted de-novo assembly via reference\n"

workflow {

    INPUT_CHECK (
        ch_input
    )

    inreads = INPUT_CHECK.out.reads

    if (params.subsample_raw) {

        SUBSAMPLE_FASTQ(
            inreads,
            params.subsample_raw
        )

        inreads = SUBSAMPLE_FASTQ.out.reads
    }

    FASTP_MULTIQC (
        inreads,
        params.adapter_fasta,
        params.save_merged,
        params.skip_fastp,
        params.skip_multiqc
    )

    ch_sample_input = FASTP_MULTIQC.out.reads

    PROFILE_READS(
        ch_sample_input,
        file(params.kraken2_db),
        file(params.taxids)
    )

    ch_sample_input = PROFILE_READS.out.profiled_reads

    CONTIG_GEN(
        ch_sample_input,
        params.contig_method,
        file(params.refs)
    )

    CONSENSUS_ASSEMBLY(
        CONTIG_GEN.out.contigs,
        CONTIG_GEN.out.reads,
    )

}
