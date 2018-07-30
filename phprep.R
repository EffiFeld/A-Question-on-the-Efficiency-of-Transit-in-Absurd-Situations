View(full_philly)
rm(list=ls())
library(plyr)

load("~/DCFULLS/full5.RData")
class(full1)


DC_full <- rbind(full1, full2, full3,full4,full5)



foo <- as.list(c$response.route.waypoint)
foo1 <- lapply(foo, "[", c("originalPosition.latitude", "originalPosition.longitude"))

as.vector(unlist(foo1[[5541]]))
foo2 <- lapply(foo1, unlist)
foo3 <- lapply(foo2, as.vector)
foo4 <- as.data.frame(do.call(rbind, foo3))
colnames(foo4) <- c("startLat", "endLat", "startLon", "endLon")
foo4[666,]



###
good_routes_ny[14,8][[1]] #this is the route basics;; this
#line to this line
###

good_routes_ph <- c %>%
  select("response.metaInfo.timestamp":"response.language")%>%
  na.omit() 

good_routes_ph <- cbind(good_routes_ph, foo4)


failed_routes_ph <- c %>%
  select("X_type":"metaInfo.interfaceVersion") %>%
  na.omit()


nrow(good_routes_ph) + nrow(failed_routes_ph)

play_PH <- good_routes_ph %>%
  select("response.route.publicTransportLine", 
         "response.route.summary.distance", "response.route.summary.baseTime", "startLat":"endLon")%>%
  filter(startLat != endLat, startLon != endLon)


foo[[5000]]
foo <- as.list(play_PH$response.route.publicTransportLine)
names(play_DC)

foo[[5]]
foo3 <- lapply(foo, "[", c("lineName", "destination", "type"))

ID1 <- 1:nrow(play_PH)
foo2 <- mapply(cbind, foo3, ID1)

ID <- play_PH[,4:7]

ID$id_trip <- 1:nrow(play_PH)


namefoo <- names(foo2[[1]])
foo2 <- lapply(foo2, unname)
namefoo
namefoo[4] <- "id_trip"

foo2[[3030]]
install.packages("data.table")
library(data.table)

transit_lines <- ldply(foo2, data.frame)
head(transit_lines)
transit_lines <- transit_lines[,1:8]
names(transit_lines) <- namefoo

transit_lines <- left_join(transit_lines, ID, by= "id_trip" )
tail(transit_lines)
gg <- rbind.data.frame(foo2)

save(transit_lines, file = "PH_transit_lines.RData")
save(failed_routes_ph, file = "failed_routes_ph.RData")
save(good_routes_ph, file = "good_routes_ph.RData")
save(DC_full, file = "DC_full.RData")
save(c, file = "PH_full.RData")
