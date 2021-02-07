#!/usr/bin/env bash

#wait for the SQL Server to come up
wait-for-port --host=localhost --timeout=300 1433
sleep 30s

if [ -z ${RECREATEDB+x} ]; then
    echo "Database is used from volume."
    RECREATE_DB=0
else
    if [[ $(fgrep -ix $RECREATEDB <<< "TRUE") ]]; then
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
    if [[ $(fgrep -ix $RECREATEUSER <<< "TRUE") ]]; then
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