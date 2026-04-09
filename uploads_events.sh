#!/bin/bash
source "$(pwd)/.env"

# 1. Get a unique list of Event Names from the filenames
# Filename pattern: 1775652869106-2026-03-06_EventName_ID.csv
# We split by '_' and take the 2nd field
events=$(ls *.csv | cut -d'_' -f2 | sort | uniq)
#events=$(ls *2026-03-09*.csv | cut -d'_' -f2 | sort | uniq)
#events=("LightningInteraction")

for event in $events; do
    # Convert event name to lowercase for the folder structure
    folder_name=$(echo "$event" | tr '[:upper:]' '[:lower:]')
    s3_path="s3://$BUCKET_NAME/crma/sf_elf_$folder_name"
    
    echo "Processing Event: $event -> $s3_path"

    # 2. Copy all files for this specific event to the S3 folder
    # We use a wildcard to match *_EventName_*.csv
    aws s3 cp . "$s3_path/" \
        --recursive \
        --exclude "*" \
        --include "*_${event}_*.csv" \
        --profile "$PROFILE"

    # 3. Create schema_sample.csv
    # Take the first matching file for this event
    sample_file=$(ls *_${event}_*.csv | head -n 1)
    
    if [ -f "$sample_file" ]; then
        echo "Generating schema sample from $sample_file..."
        
        # Grab first two lines
        head -n 2 "$sample_file" > schema_sample.csv
        
        # Copy sample to S3
        aws s3 cp schema_sample.csv "$s3_path/schema_sample.csv" --profile "$PROFILE"

        # Clean up local temporary sample file
        rm schema_sample.csv
    fi
    
    echo "------------------------------------------"
done

echo "Done!"