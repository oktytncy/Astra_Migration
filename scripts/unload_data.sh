#!/bin/bash

# Edit installation path (path where DSBULK files are extracted)
INSTALLATION_PATH=/Users/oktay.tuncay/Desktop/DataStax_Notes/Migration/test_dsbulk


# Define the base path for the command
DSBULK_PATH="$INSTALLATION_PATH/dsbulk-1.11.0/bin/dsbulk"
CONFIG_FILE="$INSTALLATION_PATH/dsbulk.conf"
BASE_URL="$INSTALLATION_PATH/data"
BUNDLE_PATH="$INSTALLATION_PATH/envs/scb-source-db.zip"
USERNAME="abcde"
PASSWORD="ajdjjfEl......"
TABLE_LIST="$INSTALLATION_PATH/table_list.sql"

# Read each line from the file containing the list of tables
while read line; do
    # Extract the keyspace and table name
    KEYSPACE=$(echo "$line" | cut -d '.' -f 1)
    TABLE=$(echo "$line" | cut -d '.' -f 2)

    # Generate the URL for data unload
    URL="$BASE_URL/$KEYSPACE/$TABLE"

    # Execute the dsbulk unload command
    $DSBULK_PATH unload -k $KEYSPACE -t $TABLE -f $CONFIG_FILE \
    -url $URL \
    -b $BUNDLE_PATH \
    -u $USERNAME \
    -p $PASSWORD
done < "$TABLE_LIST"
