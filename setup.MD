# Step-by-step AstraDB migration via dsbulk

## Installation and Preparation

1.	Install Astra CLI from the [link](https://docs.datastax.com/en/astra-cli/0.2/installation.html)

2.	Log in to AstraDB, go to the Tokens tab on the left of the screen, select the Tokens tab again, generate a token in the Organization Administrator role, and save. This step is for the source database.

    **Example:**
    ```
    {
    "clientId": "abcde....",
    "secret": "mZI1FvI.....................JeZge+xypN0DEMBRwLJlS1SD,1.s",
    "token": "AstraCS:Jbsbsb....................."
    }
    ```
3.	Repeat step 2 for the Target Database.

4.	Export the tokens generated in the previous step.

    ```bash
    export source_token="AstraCS:XYZ..."
    export target_token="AstraCS:XYZ..."
    ```

5. Setup astracli with the below command, the token will be saved so that you’re authorized to run the CLI commands.

    > **Note:** Make sure you are not using Python 3.12.

    ```bash
    astra setup --token $source_token
    ```

    **Sample Output:**
    ```bash
    % astra setup --token $source_token
    [OK]    Configuration has been saved.
    [OK]    Setup completed.
    [INFO]  Enter 'astra help' to list available commands.
    ```
6. List created databases.

    ```bash
    astra db list
    ```

    **Sample Output:**
    ```bash
	% astra db list
	+---------------------+--------------------------------------+--------------+-------+---+-----------+
	| Name                | id                                   | Regions      | Cloud | V | Status    |
	+---------------------+--------------------------------------+--------------+-------+---+-----------+
	| TestVectorDB        | 17061e68-e273-4481-808b-f1ad9b63d2ce | us-east-1    | aws   | ■ | ACTIVE    |
	| TestNonVector       | 6c6d08ca-fa2a-488f-b125-bc56f44fe784 | us-east-1    | aws   |   | ACTIVE    |
	| Source_DB           | 2a050779-021e-4361-a149-f04cbb4897d7 | europe-west2 | gcp   |   | ACTIVE    |
	| Target_DB           | fcfbe5c1-f40a-4937-a824-3b5fd9149cdd | europe-west2 | gcp   |   | ACTIVE    |
	+---------------------+--------------------------------------+--------------+-------+---+-----------+
    ```
    
7. Connect the **Source Database** via cqlsh.

    > **Note:** Before start check Python version and make sure you are not using python 3.12.

    **Sample Output:**
    ```bash
     % python --version
    Python 3.11.6
    ```

    ```bash
    astra db cqlsh Source_DB -v --token $source_token
    ```

8. Make a list of the tables to be migrated. Default keyspaces ***system_auth, system_schema, datastax_sla, data_endpoint_auth, system and system_traces*** should not be included because the target database contains default keyspaces. 
The following command will work by excluding the default keyspaces.

    ```bash
    astra db cqlsh Source_DB --token $source_token -e "SELECT keyspace_name, table_name FROM system_schema.tables;" | awk 'NR > 3 && /^[[:space:]]*keyspace/ {print $1"."$3}' | grep -v -w system | grep -v -w system_schema | grep -v -w data_endpoint_auth | grep -v -w system_auth | grep -v -w datastax_sla | grep -v -w system_traces > table_list.sql
    ```

9. Verify that the table list is not missing.

    > **Important:** You can see how many tables have been written to the table_list.sql file with the **cat table_list.sql** command. Check the file to verify that no tables are missing.

## Migrating the Metadata

1. Export source and target database names.

    ```bash
    export source_db="Source_DB"
    export target_db="Target_DB"
    ```

2. Copy the [export_metadata.sh](scripts/export_metadata.sh) file to the directory where the migration will be performed. And, add the executable permission to a file

    ```bash
    chmod +x export_metadata.sh
    ```

    Run the script and export metadata from the source database

    ```bash
    ./export_metadata.sh
    ```
3. After execution, an output called metadata_dump.cql containing the metadata of the tables and keyspaces will be generated. Verify that the content is correct by checking the file.

4. Create all keyspaces in the target database. You can find the names of the keyspaces that need to be created in the middle of the page in the Overview tab of the database after logging in to AstraUI.

    ![keyspaces](/pics/1.png)

5. Create all tables in the **Target Database** using the following command.

    ```bash
    astra db cqlsh $target_db --token $target_token -f all_tables_schema.cql
    ```

6. Verify that all tables are created with the help of the command below.

    ```bash
    astra db cqlsh $target_db --token $target_token -e "SELECT keyspace_name, table_name FROM system_schema.tables;" | grep -v -w system | grep -v -w system_schema | grep -v -w data_endpoint_auth | grep -v -w system_auth | grep -v -w datastax_sla | grep -v -w system_traces
    ```

## Data Migrating 

### Export Data

1. Download dsbulk Utility from the [link](https://downloads.datastax.com/#bulk-loader) and extract tar file to the directory where the migration will be performed.

    ```bash
    % tar -xf dsbulk-1.11.0.tar.gz -C /target/directory
    ```

2. Copy the shared [dsbulk.conf](scripts/dsbulk.conf) file to the directory where the migration will be performed.

3. [Download](https://docs.datastax.com/en/astra-db-serverless/drivers/secure-connect-bundle.html) the secure bundle files for both the source and target databases, and move them to the directory that needs to be migrated.

4. Create a data folder in the directory where the migration will be performed. This directory will be used for data to be exported.

5. Copy the shared [unload_data.sh](scripts/unload_data.sh)
 file to this directory where the migration will be performed and edit the following parameters

    ```bash
    INSTALLATION_PATH= #directory where the migration will be performed 
    SOURCE_BUNDLE_PATH=#SOURCE DB BUNDLE ZIP FILE
    SOURCE_USERNAME=#SourceDB clientId, created in step-2 in Installation and Preparation
    SOURCE_PASSWORD=#SourceDB secret, created in step-2 in Installation and Preparation
    TABLE_LIST="$INSTALLATION_PATH/table_list.sql"
    ```

    Add the executable permission to a file
    ```bash
    chmod +x unload_data.sh 
    ```

6. Export data from the source database.

    ```bash
    ./unload_data.sh
    ```

7. Check the output file and data directory to confirm that the files have been generated. 

### Import Data

1. Copy the shared [load_data.sh](scripts/load_data.sh) file to this directory where the migration will be performed and edit the following parameters

    ```bash
    INSTALLATION_PATH= #path where DSBULK files are extracted
    SOURCE_BUNDLE_PATH=#Target DB BUNDLE ZIP FILE
    SOURCE_USERNAME=#TargetDB clientId, created in step-3 in Installation and Preparation
    SOURCE_PASSWORD=#TargetDB secret, created in step-3 in Installation and Preparation
    TABLE_LIST="$INSTALLATION_PATH/table_list.sql"
    ```

    Add the executable permission to a file
    ```bash
    chmod +x load_data.sh
    ```

2. Import the data from tha data folder to the target database.

    > If the data migration is done for testing purposes before, the tables in the target database must be truncated before data migration. The Truncate step is shared as an option at the end of the document.

    > **IMPORTANT:** Do **NOT** do the truncate step in the **Source Database**.

    ```bash
    ./load_data.sh
    ```

### Verification

1. Copy the [count_tables.sh](scripts/count_tables.sh) file to the directory where the migration is performed.

    ```bash
    chmod +x count_tables.sh 
    ```

    ```bash
    ./count_tables.sh $target_token $target_db
    ./count_tables.sh $source_token $source_db
    ```


### Optional - Truncate the tables in the target database 

1. Perform this step if you are going to run the data migration step more than once for testing purposes. Copy the shared [truncate_tables.sh](scripts/truncate_tables.sh) file to the directory where the migration is performed.

    ```bash
    chmod +x truncate_tables.sh 
    ```

    ```bash
    ./truncate_tables.sh
     ```
