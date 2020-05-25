Using this project you can create your own Microsoft SQL database docker container prepared to be used as database for Intershop Commerce Management for development purposes.

---

To get a locally running database in your docker environment the following steps are necessary.

Clone or download the project and change to the project folder
```
git clone https://github.com/IntershopCommunicationsAG/mssql-intershop-docker.git

cd mssql-intershop-docker
```
Build the container image
```
docker build . --tag mssql-intershop
```
Run the container
```
docker run -d -p 1433:1433 --name mssql-intershop mssql-intershop
```

---

To connect your local ICM development environment with the local docker mssql database your configuration in the `environment.properties` of your development machine should look like this.
```
# Database configuration
databaseType = mssql
jdbcUrl = jdbc:sqlserver://localhost:1433;database=DB; 
databaseUser = intershop 
databasePassword = intershop

# these partly Oracle specific settings are still needed for the deployment script
databaseHost = DB
databasePort = 1433 
databaseTnsAlias = ISSERVER.world 
databaseServiceName = XE
oracleClientDir = C:/Oracle/client12cR1
```

---

**Note**

If you clone and build the docker container on a Windows environment make sure the line endings of the `startup.sh` script are Linux style before building the container image. Otherwise you will get the following errors when running the container.

```
/startup.sh: line 2: $'\r': command not found
: invalid signal specificationM
/startup.sh: line 4: $'\r': command not found
/startup.sh: line 5: $'\r': command not found
/startup.sh: line 6: $'\r': command not found
/startup.sh: line 7: $'wait\r': command not found
```
