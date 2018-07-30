library(plyr)

load("~/DCFULLS/full5.RData")
class(full1)


DC_full <- rbind(full1, full2, full3,full4,full5)



foo <- as.list(DC_full$response.route.waypoint)
foo1 <- lapply(foo, "[", c("originalPosition.latitude", "originalPosition.longitude"))

as.vector(unlist(foo1[[5541]]))
foo2 <- lapply(foo1, unlist)
foo3 <- lapply(foo2, as.vector)
foo4 <- as.data.frame(do.call(rbind, foo3))
colnames(foo4) <- c("startLat", "endLat", "startLon", "endLon")

DC_full <- cbind(DC_full, foo4)



###
good_routes_ny[14,8][[1]] #this is the route basics;; this
#line to this line
###

good_routes_dc <- DC_full %>%
  select("response.metaInfo.timestamp":"response.language")%>%
  na.omit() 

good_routes_dc <- cbind(good_routes_dc, foo4)


failed_routes_dc <- DC_full%>%
  select("X_type":"metaInfo.interfaceVersion") %>%
  na.omit()


nrow(good_routes_dc) + nrow(failed_routes_dc)



play_DC <- good_routes_dc %>%
  select("response.route.publicTransportLine", 
         "response.route.summary.distance", "response.route.summary.baseTime", "startLat":"endLon")%>%
  filter(startLat != endLat, startLon != endLon)


foo[[660]]
foo <- as.list(play_DC$response.route.publicTransportLine)
names(play_DC)
tfoo_good <- play_DC[,4:7]
tfoo_good <- as.list(tfoo_good)


foo1 <- lapply(foo, function(x) cbind(x, 1))

foo[[5]]

ID1 <- 1:nrow(play_DC)
foo2 <- mapply(cbind, foo, ID1)

ID <- play_DC[,4:7]

ID$id_trip <- 1:nrow(play_DC)

namefoo <- names(foo2[[1]])
foo2 <- lapply(foo2, unname)

namefoo[8] <- "id_trip"
transit_lines <- ldply(foo2, data.frame)

transit_lines <- transit_lines[,1:8]
names(transit_lines) <- namefoo

transit_lines <- left_join(transit_lines, ID, by= "id_trip" )
tail(transit_lines)

save(transit_lines, file = "DC_transit_lines.RData")
save(failed_routes_dc, file = "failed_routes_dc.RData")
save(good_routes_dc, file = "good_routes_dc.RData")
save(DC_full, file = "DC_full.RData")
