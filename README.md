Using this project you can create your own Microsoft SQL database docker container prepared to be used as database for Intershop Commerce Management for development purposes. 

To build the container image use the following command:
```
docker build . --tag companyname/mssql-intershop
```

To run the container use:
```
docker run -d -p 1433:1433 companyname/mssql-intershop
```

Your configuration in environment.properties on your development machine should look like this:
```
databaseType=mssql
intershop.jdbc.url =jdbc:sqlserver://localhost:1433;database=db
intershop.jdbc.user=intershop
intershop.jdbc.password=intershop
```




