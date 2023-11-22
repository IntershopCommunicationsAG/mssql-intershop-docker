#!/usr/bin/env bash

set -x

#wait for the SQL Server to come up
wait-for-port --host=localhost --timeout=300 1433
sleep 30s

if [ -z ${RECREATEDB+x} ]; then
    echo "Database is used from volume."
    RECREATE_DB=0
else
    RECREATEDB=$(echo "$RECREATEDB" | tr '[:upper:]' '[:lower:]')
    if [[ $RECREATEDB -eq 1 || "$RECREATEDB" = true ]]; then
        echo "Database will be recreated - all data are droped."
        RECREATE_DB=1
    else
        echo "Database is used from volume."
        RECREATE_DB=0
    fi
fi

if [ -z ${RECREATEUSER+x} ]; then
    echo "Database is used with the existing database user."
    RECREATE_USER=0
else
    RECREATEUSER=$(echo "$RECREATEUSER" | tr '[:upper:]' '[:lower:]')
    if [[ $RECREATEUSER -eq 1 || "$RECREATEUSER" = true ]]; then
        echo "Database user will be recreated."
        RECREATE_USER=1
    else
        echo "Database is used with the existing database user."
        RECREATE_USER=0
    fi
fi

export RECREATE_DB RECREATE_USER

#run the setup script to create the DB and the schema in the DB
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -d master -i setupdb.sql

IFS=',' read -ra dbUsers <<< "$ICM_DB_USER"
IFS=',' read -ra dbNames <<< "$ICM_DB_NAME"
IFS=',' read -ra dbPasswords <<< "$ICM_DB_PASSWORD"
for i in "${!dbUsers[@]}"
do
    /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -d master -q "EXEC createIcmDB @DBName = ${dbNames[i]}, @UserID = ${dbUsers[i]}, @Password = ${dbPasswords[i]}, @RecreateDB = ${RECREATE_DB}, @RecreateUser = ${RECREATE_USER}"
done


