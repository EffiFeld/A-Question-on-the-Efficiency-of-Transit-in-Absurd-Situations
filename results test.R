library(plyr)

load("~/11_NYFulls/full6")
class(full1)

names(good_routes_ny)
View(full1)

NY_full <- rbind(full1, full2, full3,full4,full5,full6)
NY_full <- cbind(NY_full, tfoo)


foo <- as.list(NY_full$response.route.waypoint)
foo1 <- lapply(foo, "[", c("originalPosition.latitude", "originalPosition.longitude"))

foo1[[54541]]
tfoo[54541,]
NY_full[54541,33:36]

###
good_routes_ny[14,8][[1]] #this is the route basics;; this
#line to this line
###

good_routes_ny <- NY_full %>%
  select("response.metaInfo.timestamp":"response.language", "startLat":"endLon")%>%
  na.omit() 

failed_routes_ny <- NY_full%>%
  select("X_type":"metaInfo.interfaceVersion","startLat":"endLon" ) %>%
  na.omit()

nrow(good_routes_ny) + nrow(failed_routes_ny)


tfoo[6,]
play_NY <- good_routes_ny %>%
  select("response.route.publicTransportLine", 
        "response.route.summary.distance", "response.route.summary.baseTime", "startLat":"endLon")%>%
  filter(startLat != endLat, startLon != endLon)



foo <- as.list(play_NY$response.route.publicTransportLine)
names(play_NY)
tfoo_good <- play_NY[,4:7]
tfoo_good <- play_NY[,4]
tfoo_good <- as.list(tfoo_good)
tfoo_good[[3]]
foo1 <- lapply(foo, function(x) cbind(x, 1))

foo[[5]]
foo1 <- lapply(foo, "[", c("originalPosition.latitude", "originalPosition.longitude"))

ID <- 1:nrow(play_NY)
foo2 <- mapply(cbind, foo, ID)

ID <- play_NY[,4:7]

ID$id_trip <- 1:nrow(play_NY)


namefoo <- names(foo2[[1]])
foo2 <- lapply(foo2, unname)

transit_lines <- do.call("rbind", foo2)


namefoo[8] <- "id_trip"
transit_lines <- ldply(foo2, data.frame)

transit_lines <- transit_lines[,1:8]
names(transit_lines) <- namefoo

transit_lines <- left_join(transit_lines, ID, by= "id_trip" )


save(transit_lines, file = "NY_transit_lines.RData")
save(failed_routes_ny, file = "failed_routes_ny")
save(good_routes_ny, file = "good_routes_ny")
save(NY_full, file = "NY_full.RData")
