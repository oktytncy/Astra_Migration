#!/bin/bash

# Read each line from the file
while IFS= read -r line
do
    # Construct and execute the truncate command for each table
    astra db cqlsh $target_db --token $target_token -e "truncate $line"
done < "table_list.sql"
