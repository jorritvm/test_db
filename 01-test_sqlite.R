library(RSQLite)

rm(list = ls())
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# get data
data("mtcars")
mtcars$car_names <- rownames(mtcars)
rownames(mtcars) <- c()
head(mtcars)

# create db & write the data
conn <- dbConnect(RSQLite::SQLite(), "cars-db.db")
dbWriteTable(conn, "cars_data", mtcars)

# verify
dbListTables(conn)

# get db info
dbGetInfo(conn)

# add new data
car <- c('Camaro', 'California', 'Mustang', 'Explorer')
make <- c('Chevrolet','Ferrari','Ford','Ford')
df1 <- data.frame(car,make)
car <- c('Corolla', 'Lancer', 'Sportage', 'XE')
make <- c('Toyota','Mitsubishi','Kia','Jaguar')
df2 <- data.frame(car,make)
# Add them to a list
dfList <- list(df1,df2)
# Write a table by appending the data frames inside the list
for(k in 1:length(dfList)){
  dbWriteTable(conn,"Cars_and_Makes", dfList[[k]], append = TRUE)
}
# List all the Tables
dbListTables(conn)

# verify
x = dbGetQuery(conn, "SELECT * FROM Cars_and_Makes")
x 
str(x)

# some more advanced sql queries:
dbGetQuery(conn,"SELECT car_names, hp, cyl FROM cars_data
                 WHERE car_names LIKE 'M%' AND cyl IN (6,8)")
dbGetQuery(conn,"SELECT cyl, AVG(hp) AS 'average_hp', AVG(mpg) AS 'average_mpg' FROM cars_data
                 GROUP BY cyl
                 ORDER BY average_hp")

# use a variable to define values in sql query
# Lets assume that there is some user input that asks us to look only into cars that have over 18 miles per gallon (mpg)
# and more than 6 cylinders
mpg <-  18
cyl <- 6
Result <- dbGetQuery(conn, 'SELECT car_names, mpg, cyl FROM cars_data WHERE mpg >= ? AND cyl >= ?', params = c(mpg,cyl))
Result

# get query vs execute
# Visualize the table before deletion
dbGetQuery(conn, "SELECT * FROM cars_data LIMIT 10")
# Delete the column belonging to the Mazda RX4. You will see a 1 as the output.
dbExecute(conn, "DELETE FROM cars_data WHERE car_names = 'Mazda RX4'")
# Visualize the new table after deletion
dbGetQuery(conn, "SELECT * FROM cars_data LIMIT 10")

# reinsert deletd record
dbExecute(conn, "INSERT INTO cars_data VALUES (21.0,6,160.0,110,3.90,2.620,16.46,0,1,4,4,'Mazda RX4')")

# Close the database connection to CarsDB
dbDisconnect(conn)
