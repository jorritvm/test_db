# benchmarking sqlite with data.table

library(data.table)
library(dtplyr)
library(dplyr)
library(jrutils)
library(tictoc)

# create A BIG data frame
dt = as.data.table(nycflights13::flights)
dtlist = list()
for (i in 2000:2020) {
  dtlist[[i]] = dt
}
df = data.frame(rbindlist(dtlist, idcol = "year"))
print_var_size(df) # 840MB nice!


## TEST 1 WRITE FROM MEMORY TO DISK  
# write this dataframe as a data.table RDS to the disk
tic("writing data table to RDS")
saveRDS(object = as.data.table(df), file = "flights_rds.RDS")
toc() # 30.56s -> 141MB
tic("writing data table to RDS")
saveRDS(object = as.data.table(df), file = "flights_rds_uncompressed.RDS", compress = FALSE)
toc() # 2.99s -> 952MB

# write it as a sqlite
tic("writing to sqlite")
con <- dbConnect(RSQLite::SQLite(), "flights2_db.db")
dbCreateTable(con, "flights", df)
dbAppendTable(con, "flights", df)
dbDisconnect(con)
toc() # 7.75s -> 478MB

# result : sqlite is a lot faster than writing compressed RDS files but a lot 
# slower than writing uncompressed RDS. The file size of sqlite is in between both


## TEST 2: reading from disk and perform a query
# data table : read entire RDS file, then do query in memory
tic("total rds work")
tic("reading rds")
dt = readRDS("flights_rds.RDS") 
toc() # 4.85s
tic("aggregating")
x = dt[distance > 200, 
       .(mean_air = mean(air_time, na.rm = TRUE)), 
       by = .(year, origin, dest)][order(-mean_air)]
toc() # 0.2s
x
toc() # 5.05s

# write the query in dplyr and perform the operation in sqlite
tic("reading the whole table entirely from db")
con <- dbConnect(RSQLite::SQLite(), "flights2_db.db")
y = dbReadTable(con, "flights")
dbDisconnect(con)
toc() #12.56s

tic("aggregation query in dB")
con <- dbConnect(RSQLite::SQLite(), "flights2_db.db")
result =  tbl(con, "flights") %>%
          filter(distance > 200) %>%
          group_by(year, origin, dest) %>%
          summarise(mean_air = mean(air_time, na.rm = TRUE)) %>%
          arrange(desc(mean_air)) %>%
          collect()
dbDisconnect(con)
toc() # 5 sec -> about the same time as the data.table operation, 
      # but you don't have anything in memory now...

## TEST 3:
# perform the DT aggregation using DTplyer
tic("aggregating using dtplyr")
z = dt %>%
  filter(distance > 200) %>%
  group_by(year, origin, dest) %>%
  summarise(mean_air = mean(air_time, na.rm = TRUE)) %>%
  arrange(desc(mean_air)) %>%
  as.data.table()
toc() # 0.75s
identical(x,z)


