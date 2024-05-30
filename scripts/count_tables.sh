#!/bin/bash

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 token database"
    exit 1
fi

# Assign the first argument to token and the second to database
token="$1"
database="$2"

# Read each line from table_list.sql
while IFS= read -r line
do
    # Split the line into keyspace and table variables
    keyspace=$(echo "$line" | cut -d'.' -f1)
    table=$(echo "$line" | cut -d'.' -f2)

    # Debug output to see what is being processed
    echo "Processing keyspace: $keyspace, table: $table"

    # Execute the count command for the keyspace and table
    astra db count $database --token $token -k "$keyspace" -t "$table"
done < "table_list.sql"
