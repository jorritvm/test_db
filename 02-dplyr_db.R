# dplyr test for DB and data.table

library(RSQLite)
library(dplyr)


rm(list = ls())
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# connect to the DB
conn <- dbConnect(RSQLite::SQLite(), "flights_db.db")

# List all the Tables
dbListTables(conn)

# our dataset for today
str(nycflights13::flights)

# add a table to this DB - using this dplyr method the time_hour is bad
copy_to(conn, nycflights13::flights, "flights",
        temporary = FALSE, 
        indexes = list(
          c("year", "month", "day"), 
          "carrier", 
          "tailnum",
          "dest"
        )
)
str(dbReadTable(conn, "flights"))

# second try using DBI functions is equally bad
dbCreateTable(conn, "flights2", nycflights13::flights)
dbAppendTable(conn, "flights2", nycflights13::flights)
dbListTables(conn)
str(dbReadTable(conn, "flights2"))

# trying to convert it
from_memory = nycflights13::flights[1, "time_hour"]
from_memory
from_db = as.POSIXct(dbReadTable(conn, "flights")[1, "time_hour"], origin = "1970-01-01")
from_db
# -> this does not work, make sure to convert dates into iso8601 before putting it in sqlite

# List all the Tables
dbListTables(conn)

# dplyr does SQL in the background (but lazilly):
flights_db <- tbl(conn, "flights")
q = flights_db %>% select(year:day, dep_delay, arr_delay)
show_query(q)

flights_db <- tbl(conn, "flights")
flights_db %>% select(year:day, dep_delay, arr_delay)
flights_db %>% filter(dep_delay > 240)
flights_db %>% 
  group_by(dest) %>%
  summarise(delay = mean(dep_time))




# Close the database connection to CarsDB
dbDisconnect(conn)
