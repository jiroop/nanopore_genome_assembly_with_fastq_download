#!/usr/bin/env python3
"""
Script to annotate FASTA sequence files with information from Diamond BLAST results.

This script performs three main tasks:
1. Reads a Diamond BLAST results file and extracts annotation information
2. Updates FASTA headers in a protein file with this annotation data
3. Updates FASTA headers in a transcript file with the same annotation data

Each sequence gets a new header containing: gene name, species, sequence identity,
coverage metrics, E-value, and Swiss-Prot ID.
"""


def parse_annotations(annotation_file):
    """
    Parse the Diamond BLAST results file and create an annotation dictionary.
    
    This function reads through the Diamond TSV results file and extracts key
    information for each BLAST match. It creates a dictionary where:
    - Keys: unique gene/sequence IDs (extracted from the first column)
    - Values: formatted header strings with all annotation information
    
    The header format includes:
    >gene|species|%ID|query_coverage|subject_coverage|evalue|swissprot_id|original_id
    
    Args:
        annotation_file: Path to the diamond_results.tsv file
        
    Returns:
        Dictionary mapping sequence IDs to formatted annotation headers
    """
    annotation_dict = {}
    
    # Open and read through the Diamond results file line by line
    with open(annotation_file, "r") as f:
        for line in f:
            split_line = line.strip().split("\t")
            
            # Extract the unique gene label from the first column
            # It contains the sequence ID followed by "_eAED:" and other info
            # We only want the part before "_eAED:"
            label = split_line[0].split("_eAED:")[0]
            
            # Parse the hit description (second column) to extract species and gene info
            # Check if this is a Swiss-Prot entry (contains "sp|" in the description)
            if "sp|" in split_line[1]:

                species = "sp=" + split_line[1].split("|")[2].split("_")[1]
                gene = "gene=" + split_line[1].split("|")[2].split("_")[0]
                swissprot_id = "SPID=" + split_line[1].split("|")[1]
            else:
                # Non-Swiss-Prot hit (likely from YEAST database or similar)
                species = "sp=YEAST"
                gene = "gene=" + split_line[1]
                swissprot_id = "SPID=NA"
            
            # Extract BLAST statistics from Diamond output columns
            perc_ID = "prot_%ID=" + str(split_line[2])
            perc_query_coverage = "prot_Qcov=" + str(split_line[12])
            perc_subject_coverage = "prot_Scov=" + str(split_line[13])
            evalue = "prot_eval=" + str(split_line[10])
            
            # Construct the new header with all annotation information
            header = ">" + gene + "|" + species + "|" + perc_ID + "|" + perc_query_coverage + "|" + perc_subject_coverage + "|" + evalue + "|" + swissprot_id + "|" + split_line[0]
            
            # Store in dictionary with sequence ID as key
            annotation_dict[label] = header
    
    return annotation_dict


def annotate_fasta_file(input_fasta, output_fasta, annotation_dict, file_type):
    """
    Read a FASTA file and write a new file with updated headers from annotations.
    
    This function processes a FASTA file sequence by sequence:
    1. Reads header lines (starting with ">")
    2. Extracts the sequence ID from the header
    3. Looks up the ID in the annotation dictionary
    4. Writes either the annotated header or the original header
    5. Writes the sequence data
    
    If a sequence ID is not found in the annotation dictionary, it's added with
    the original ID as the header value. This allows us to track which sequences
    were not annotated.
    
    Args:
        input_fasta: Path to input FASTA file to process
        output_fasta: Path to output FASTA file to write
        annotation_dict: Dictionary mapping sequence IDs to annotation headers
                        (will be modified if unannotated sequences are found)
        file_type: String describing the sequence type ("Protein" or "Transcript")
                  Used only for logging/reporting
    """
    # Open output file for writing
    with open(output_fasta, "w") as outfile:
        # Initialize variables to track sequences and annotations
        sequence = ""  # Buffer to accumulate sequence lines
        no_annotation_counter = 0  # Count of sequences without annotations
        annotation_counter = 0  # Count of sequences with annotations
        
        # Open and read the input FASTA file
        with open(input_fasta, "r") as seq_file:
            for line in seq_file:
                # Check if this line is a header line (starts with ">")
                if line.startswith(">"):
                    # If we have a previous sequence buffered, write it now
                    # (We wait until the next header to write so we can check
                    # the ID against the annotation dictionary)
                    if sequence != "" and seq_id in annotation_dict:
                        # Write the annotation header and the sequence
                        outfile.write(annotation_dict[seq_id] + "\n")
                        outfile.write(sequence)
                        sequence = ""  # Reset sequence buffer
                    
                    # Extract the sequence ID from the header
                    # Remove the ">" at the beginning and take only the first word
                    seq_id = line.strip().split(" ")[0][1:]
                    
                    # Check if this sequence ID has an annotation
                    if seq_id not in annotation_dict:
                        # No annotation found
                        no_annotation_counter += 1
                        # Add it to the dictionary with the original ID as value
                        # This marks it as "unannotated" for this file type
                        annotation_dict[seq_id] = seq_id
                    else:
                        # Annotation found
                        annotation_counter += 1
                
                else:
                    # This is a sequence line, not a header
                    # Append it to the buffer (we'll write it when we hit the next header)
                    sequence += line
    
    # Print statistics for this file
    print(f"{file_type} sequences with Diamond annotations: {annotation_counter}")
    print(f"{file_type} sequences with no Diamond annotation: {no_annotation_counter}")


def main():
    """
    Main entry point for the script.
    
    Orchestrates the workflow:
    1. Parse Diamond results into an annotation dictionary
    2. Make two independent copies (one for proteins, one for transcripts)
    3. Process protein FASTA file with first copy
    4. Process transcript FASTA file with second copy
    
    We use separate copies so that unannotated sequences discovered during
    protein processing don't affect the transcript processing, keeping
    the annotations independent for each file type.
    """
    
    # STEP 1: Parse the Diamond BLAST results file
    print("Reading Diamond BLAST results...")
    annotation_dict = parse_annotations("diamond_results.tsv")
    print(f"Loaded {len(annotation_dict)} annotations from Diamond results\n")
    
    # STEP 2: Make two independent copies of the annotation dictionary
    protein_annotation_dict = annotation_dict.copy()
    transcript_annotation_dict = annotation_dict.copy()
    
    # STEP 3: Process protein sequences
    print("Processing protein FASTA file...")
    annotate_fasta_file(
        "maker_output.all.maker.proteins.fasta",
        "final_annotated_proteins.fasta",
        protein_annotation_dict,
        "Protein"
    )
    print()  # Blank line for readability
    
    # STEP 4: Process transcript sequences
    print("Processing transcript FASTA file...")
    annotate_fasta_file(
        "maker_output.all.maker.transcripts.fasta",
        "final_annotated_transcripts.fasta",
        transcript_annotation_dict,
        "Transcript"
    )
    
    print("\nAnnotation complete!")


if __name__ == "__main__":
    main()