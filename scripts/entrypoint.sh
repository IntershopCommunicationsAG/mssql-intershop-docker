#!/usr/bin/env sh

#start SQL Server, start the script to create the DB and import the data, start the app
/usr/src/icmdb/setupdb.sh &

exec /opt/mssql/bin/sqlservr