#!/bin/bash

# Define the output file
output_file="all_tables_schema.cql"

# Check if the output file already exists and remove it to start fresh
if [ -f "$output_file" ]; then
    rm "$output_file"
fi

# If your token is not already an environment variable, set it here
# export token='your_token_here'

# Iterate through each table listed in your SQL file
cat table_list.sql | while read -r line
do
    echo "Exporting schema for table: $line"
    # Append each table's schema to the single output file, filtering out unwanted messages
    (echo "DESCRIBE TABLE $line;" | astra db cqlsh $source_db --token $source_token 2>&1 | grep -v "Cqlsh is starting") | grep -v "Improper" >> "$output_file"
done
