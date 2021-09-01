# db_test
 Test R database connections

* 01-test_sqlite.R  
Build a sqlite persistent database using the 'RSqlite' package.

* 02-dplyr_db.R  
use dplyr function "copy_to" to write to the .db file  
use dplyr syntax to query from the database

* 03-benchmark_dt_versus_sqlite.R  
create a very big dataframe (850MB)  
benchmark: write it to disk as a data.table in RDS & as a table in sqlite  
benchmark: read it from disk in its entirety
benchmark: perform a query in data table versus in sqlite
additional test: use dtplyer to create data.table code in dplyr syntax

