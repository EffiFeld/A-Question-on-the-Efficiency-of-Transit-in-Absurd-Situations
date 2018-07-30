




#Part 3: A Catastrophic Issue

Okay, I woke up the morning of the July 19th and found the two biggest roadblocks of the project waiting at my computer. What made it castrophic was that, along with these two issues, I had my first set of 90,000 routes.

The first issue was that that day, Google had begun charging for their previously free API. A disastear for my student pockets, and so close to the solution. Well, I was too close to not try and find a replacement.

The second issue was that my use of AWS had cost around $50, not something I was expected. Ooops.

Well let's try and solve the first issue first.

##Finding a Replacement for Google Routes API
Finding another API was only a mild headache. The most annoying aspect was finding one that suppored transit routes and not exclusively driving directions. To the rescue: Here API. It had everything I wanted, except that no kind soul had made an R package to easily access it. It became pretty obvious during that day of research that Here was my best option. I would have to write some of my own functions to get it to work.

###Functions
Basically, I want to take my 3 lists of 90,000 rows and 360,000 indivudal cooridnates and feed them into the Here API.  

The API requires that the link I use look like:

> route.cit.api.here .com/routing/7.2/calculateroute.json?waypoint0=52.5208%2C13.4093&waypoint1=52.5034%2C13.3295&mode=fastest%3BpublicTransport &combineChange=true&app_id=DemoAppId01082013GAL&app_code=AJKnXv84fjrb0KIHawS0Tg"

All coordinates needed to be adjusted to be strings that resemble `52.5208%2C13.4093`.


```r
here_mcoord_fix <- function(df){
  latitude <- df[,1]
  longitude <- df[,2]
  url2 <- paste0(longitude, "%2C", latitude)
  return(url2)
}
```

Now, there are several constants in the URL that can be set to variables. Then everything can be easily pasted together into proper URLS.


```r
base_url <- "https://route.cit.api.here.com/routing/7.2/calculateroute.json"
xmode <- "&mode=fastest%3BpublicTransport&combineChange=true"
#these two are different per API User
id <- "&app_id=SOME_NUMBERS_AND_LETTERS&"
code <- "app_code=SOME_NUMBERS_AND_LETTERS&departure=2018-07-18T11:00:00-05:00"
```

And here's the function that pulls everything together. It contains the `here_mcoord_fix` function within to cut steps down.


```r
get_here_urls <- function(origin, destination){
  xorigin <- here_mcoord_fix(origin)
  xdestination <- here_mcoord_fix(destination)
  z <- paste0(base_url,"?waypoint0=",xorigin, "&waypoint1=",
              xdestination, xmode, id, code, sep="")
  return(z) 
}
```

So let me show the output:

```r
load("~/R/transit_bookdown/philly_300_points.RData")
origin <- philly_300_points%>%
  select(startLon, startLat)
destination <- philly_300_points%>%
  select(endLon, endLat)

urls <- get_here_urls(origin, destination)

#Let's take a peak at a random 1 of 89700 URLs we've created.
urls[runif(1, 1,89700)]
```

```
## [1] "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.9789405411541%2C-75.1607744942566&waypoint1=40.0671834820293%2C-75.0374140686739&mode=fastest%3BpublicTransport&combineChange=true&app_id=SOME_NUMBERS_AND_LETTERS&app_code=SOME_NUMBERS_AND_LETTERS&departure=2018-07-18T11:00:00-05:00"
```




##Running this Code without Emptying my Pockets
So, I decided not to use AWS anymore...maybe if I had deep pockets I would, but I had decided to find an alternative. The first thing I learned was that I did not[^1] really fully understand parallel computing. There were better functions than `mclapply` available. The second thing I realized that I was obsessed with doing the work on the cloud. On one hand, the cloud is definietly better. On the other hand, only if you've got that cash-money.

The solution was to use the `DoParallel` package with computers that have multiple cores, thus performing parallel computations on each core.

###Getting DoParallel Up and Running

```r
#Setting up parallel with one less core than available on the computer. This is to avoid intense crashing.
no_cores <- detectCores() - 1  
cl <- makeCluster(no_cores)  
registerDoParallel(cl)  

#To see if that worked: if it returns 1 - then it didn't work
getDoParWorkers()

#To end the parallel cores
registerDoSEQ()
getDoParWorkers()
```


###Getting the functions ready to access the here API {.tabset .tabset-fade}
The first step is getting it running before going parallel and seeing what the outputs look like.

There are some messy looking results so I've tabbed this section to maintain readability. Feel free to look through it if you're interested. Each tab is a view of each output.

#### Everything
The first step is getting it running before going parallel and seeing what the outputs look like:


```r
load("~/R/transit_bookdown/GET_url_test.RData")

#We'll use one random url to test
url_test <- urls[runif(1, 1,89700)]
require(httr)
require(jsonlite)

GET_url_test <- GET(url_test)
content_url_test <-  content(GET_url_test, "text")
json_url_test <-   fromJSON(content_url_test, flatten = TRUE)
final_url_test <- as.data.frame(json_url_test)
```


####step 1

```r
GET_url_test
```

```
## Response [https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.891007017175%2C-75.1736776842591&waypoint1=39.9018409331484%2C-75.1355796363872&mode=fastest%3BpublicTransport&combineChange=true&app_id=geLVK2d13btBHVl3K7zM&app_code=YsaWhU8qeIQtiFlSVFf7gg&departure=2018-07-18T11:00:00-05:00]
##   Date: 2018-07-23 23:06
##   Status: 200
##   Content-Type: application/json;charset=utf-8
##   Size: 9.82 kB
## {"response":{"metaInfo":{"timestamp":"2018-07-23T23:06:49Z","mapVersion"...
```
There are a few good pieces of news in this code:

  *The status is 200 meaning it worked[^1]
  *The data is in JSON format
  *The size is not absurd

#### Step 2

```r
content_url_test <-  content(GET_url_test, "text")
```


```
## [1] "{\"response\":{\"metaInfo\":{\"timestamp\":\"2018-07-23T23:08:13Z\",\"mapVersion\":\"8.30.85.156\",\"moduleVersion\":\"7.2.201829-33197\",\"interfaceVersion\":\"2.6.34\",\"availableMapVersion\":[\"8.30.85.156\"]},\"route\":[{\"waypoint\":[{\"linkId\":\"+18693161\",\"mappedPosition\":{\"latitude\":40.0568444,\"longitude\":-75.1911711},\"originalPosition\":{\"latitude\":40.0567437,\"longitude\":-75.19102},\"type\":\"stopOver\",\"spot\":0.3478261,\"sideOfStreet\":\"right\",\"mappedRoadName\":\"W Mt Pleasant Ave\",\"label\":\"W Mt Pleasant Ave\",\"shapeIndex\":0},{\"linkId\":\"+18769947\",\"mappedPosition\":{\"latitude\":39.8786749,\"longitude\":-75.2075897},\"originalPosition\":{\"latitude\":39.8777652,\"longitude\":-75.2059473},\"type\":\"stopOver\",\"spot\":0.4118199,\"sideOfStreet\":\"neither\",\"mappedRoadName\":\"Fort Mifflin Rd\",\"label\":\"Fort Mifflin Rd\",\"shapeIndex\":188}],\"mode\":{\"type\":\"fastest\",\"transportModes\":[\"publicTransport\"],\"trafficMode\":\"disabled\",\"feature\":[]},\"leg\":[{\"start\":{\"linkId\":\"+18693161\",\"mappedPosition\":{\"latitude\":40.0568444,\"longitude\":-75.1911711},\"originalPosition\":{\"latitude\":40.0567437,\"longitude\":-75.19102},\"type\":\"stopOver\",\"spot\":0.3478261,\"sideOfStreet\":\"right\",\"mappedRoadName\":\"W Mt Pleasant Ave\",\"label\":\"W Mt Pleasant Ave\",\"shapeIndex\":0},\"end\":{\"linkId\":\"+18769947\",\"mappedPosition\":{\"latitude\":39.8786749,\"longitude\":-75.2075897},\"originalPosition\":{\"latitude\":39.8777652,\"longitude\":-75.2059473},\"type\":\"stopOver\",\"spot\":0.4118199,\"sideOfStreet\":\"neither\",\"mappedRoadName\":\"Fort Mifflin Rd\",\"label\":\"Fort Mifflin Rd\",\"shapeIndex\":188},\"length\":27716,\"travelTime\":9066,\"maneuver\":[{\"position\":{\"latitude\":40.0568444,\"longitude\":-75.1911711},\"instruction\":\"Head <span class=\\\"heading\\\">northeast</span> on <span class=\\\"street\\\">W Mt Pleasant Ave</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">228 m</span>.</span>\",\"travelTime\":237,\"length\":228,\"id\":\"M1\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":40.0583732,\"longitude\":-75.189389},\"instruction\":\"Turn <span class=\\\"direction\\\">left</span> onto <span class=\\\"next-street\\\">Germantown Ave</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">19 m</span>.</span>\",\"travelTime\":19,\"length\":19,\"id\":\"M2\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":40.0583732,\"longitude\":-75.189389},\"instruction\":\"Go to the stop <span class=\\\"station\\\">Germantown Av & Mt Pleasant Av</span> and take the <span class=\\\"transit\\\">bus</span> <span class=\\\"line\\\">23</span> toward <span class=\\\"destination\\\">11th St & Market St -</span>. <span class=\\\"distance-description\\\">Follow for <span class=\\\"stops\\\">43 stops</span>.</span>\",\"travelTime\":1770,\"length\":6529,\"id\":\"M3\",\"stopName\":\"Germantown Av & Mt Pleasant Av\",\"_type\":\"PublicTransportManeuverType\"},{\"position\":{\"latitude\":40.0094068,\"longitude\":-75.1509583},\"instruction\":\"Get off at <span class=\\\"station\\\">Germantown Av & Erie Av</span>.\",\"travelTime\":0,\"length\":0,\"id\":\"M4\",\"stopName\":\"Germantown Av & Erie Av\",\"nextRoadName\":\"Germantown Ave\",\"_type\":\"PublicTransportManeuverType\"},{\"position\":{\"latitude\":40.0094068,\"longitude\":-75.1509583},\"instruction\":\"Head <span class=\\\"heading\\\">east</span> on <span class=\\\"street\\\">Germantown Ave</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">28 m</span>.</span>\",\"travelTime\":41,\"length\":28,\"id\":\"M5\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":40.0092137,\"longitude\":-75.1508081},\"instruction\":\"Turn <span class=\\\"direction\\\">right</span> onto <span class=\\\"next-street\\\">W Erie Ave</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">36 m</span>.</span>\",\"travelTime\":46,\"length\":36,\"id\":\"M6\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":40.0092459,\"longitude\":-75.1512265},\"instruction\":\"Turn <span class=\\\"direction\\\">left</span> onto <span class=\\\"next-street\\\">N Broad St</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">3 m</span>.</span>\",\"travelTime\":3,\"length\":3,\"id\":\"M7\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":40.0092459,\"longitude\":-75.1513124},\"instruction\":\"Go to the station <span class=\\\"station\\\">Erie Station</span> and take the <span class=\\\"transit\\\">rail</span> <span class=\\\"line\\\">BSL</span> toward <span class=\\\"destination\\\">at&T Station</span>. <span class=\\\"distance-description\\\">Follow for <span class=\\\"stops\\\">15 stations</span>.</span>\",\"travelTime\":1610,\"length\":10420,\"id\":\"M8\",\"stopName\":\"Erie Station\",\"_type\":\"PublicTransportManeuverType\"},{\"position\":{\"latitude\":39.9167848,\"longitude\":-75.1714182},\"instruction\":\"Get off at <span class=\\\"station\\\">Oregon Station</span>.\",\"travelTime\":0,\"length\":0,\"id\":\"M9\",\"stopName\":\"Oregon Station\",\"_type\":\"PublicTransportManeuverType\"},{\"position\":{\"latitude\":39.9167848,\"longitude\":-75.1714182},\"instruction\":\"Head <span class=\\\"heading\\\">northeast</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">10 m</span>.</span>\",\"travelTime\":14,\"length\":10,\"id\":\"M10\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":39.9168277,\"longitude\":-75.1713324},\"instruction\":\"Turn <span class=\\\"direction\\\">slightly left</span> onto <span class=\\\"next-street\\\">S Broad St</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">25 m</span>.</span>\",\"travelTime\":25,\"length\":25,\"id\":\"M11\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":39.9168277,\"longitude\":-75.1713324},\"instruction\":\"Go to the stop <span class=\\\"station\\\">Oregon Av & Broad St</span> and take the <span class=\\\"transit\\\">bus</span> <span class=\\\"line\\\">68</span> toward <span class=\\\"destination\\\">69th St Transportation Center South Terminal</span>. <span class=\\\"distance-description\\\">Follow for <span class=\\\"stops\\\">16 stops</span>.</span>\",\"travelTime\":2720,\"length\":7864,\"id\":\"M12\",\"stopName\":\"Oregon Av & Broad St\",\"_type\":\"PublicTransportManeuverType\"},{\"position\":{\"latitude\":39.8836005,\"longitude\":-75.2235281},\"instruction\":\"Get off at <span class=\\\"station\\\">Enterprise Av & Fort Mifflin Rd</span>.\",\"travelTime\":0,\"length\":0,\"id\":\"M13\",\"stopName\":\"Enterprise Av & Fort Mifflin Rd\",\"nextRoadName\":\"Enterprise Ave\",\"_type\":\"PublicTransportManeuverType\"},{\"position\":{\"latitude\":39.8836005,\"longitude\":-75.2235281},\"instruction\":\"Head <span class=\\\"heading\\\">northwest</span> on <span class=\\\"street\\\">Enterprise Ave</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">32 m</span>.</span>\",\"travelTime\":42,\"length\":32,\"id\":\"M14\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":39.8837721,\"longitude\":-75.223335},\"instruction\":\"Turn <span class=\\\"direction\\\">right</span> onto <span class=\\\"next-street\\\">Fort Mifflin Rd</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">1.7 km</span>.</span>\",\"travelTime\":1723,\"length\":1713,\"id\":\"M15\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":39.8775494,\"longitude\":-75.2135289},\"instruction\":\"Turn <span class=\\\"direction\\\">left</span> onto <span class=\\\"next-street\\\">Fort Mifflin Rd</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">75 m</span>.</span>\",\"travelTime\":76,\"length\":75,\"id\":\"M16\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":39.8770881,\"longitude\":-75.2129066},\"instruction\":\"Take the street on the <span class=\\\"direction\\\">right</span>. <span class=\\\"distance-description\\\">Go for <span class=\\\"length\\\">734 m</span>.</span>\",\"travelTime\":740,\"length\":734,\"id\":\"M17\",\"_type\":\"PrivateTransportManeuverType\"},{\"position\":{\"latitude\":39.8786749,\"longitude\":-75.2075897},\"instruction\":\"Arrive at <span class=\\\"street\\\">Fort Mifflin Rd</span>.\",\"travelTime\":0,\"length\":0,\"id\":\"M18\",\"_type\":\"PrivateTransportManeuverType\"}]}],\"publicTransportLine\":[{\"lineName\":\"23\",\"companyName\":\"\",\"destination\":\"11th St & Market St -\",\"type\":\"busPublic\",\"id\":\"L1\"},{\"lineName\":\"BSL\",\"lineForeground\":\"#FF9933\",\"lineBackground\":\"#FF9933\",\"companyName\":\"\",\"destination\":\"at&T Station\",\"type\":\"railMetro\",\"id\":\"L2\"},{\"lineName\":\"68\",\"companyName\":\"\",\"destination\":\"69th St Transportation Center South Terminal\",\"type\":\"busPublic\",\"id\":\"L3\"}],\"summary\":{\"distance\":27716,\"baseTime\":9066,\"flags\":[\"noThroughRoad\",\"builtUpArea\",\"park\",\"privateRoad\"],\"text\":\"The trip takes <span class=\\\"length\\\">27.7 km</span> and <span class=\\\"time\\\">2:31 h</span>.\",\"travelTime\":9066,\"departure\":\"2018-07-18T12:00:00-04:00\",\"_type\":\"PublicTransportRouteSummaryType\"}}],\"language\":\"en-us\"}}\n"
```

#### step 3


```r
json_url_test <-   fromJSON(content_url_test, flatten = TRUE)
```


```
## $response
## $response$metaInfo
## $response$metaInfo$timestamp
## [1] "2018-07-23T23:08:13Z"
## 
## $response$metaInfo$mapVersion
## [1] "8.30.85.156"
## 
## $response$metaInfo$moduleVersion
## [1] "7.2.201829-33197"
## 
## $response$metaInfo$interfaceVersion
## [1] "2.6.34"
## 
## $response$metaInfo$availableMapVersion
## [1] "8.30.85.156"
## 
## 
## $response$route
##                                                                                                                                                                                                                                                           waypoint
## 1 +18693161, +18769947, stopOver, stopOver, 0.3478261, 0.4118199, right, neither, W Mt Pleasant Ave, Fort Mifflin Rd, W Mt Pleasant Ave, Fort Mifflin Rd, 0, 188, 40.0568444, 39.8786749, -75.1911711, -75.2075897, 40.0567437, 39.8777652, -75.19102, -75.2059473
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      leg
## 1 27716, 9066, Head <span class="heading">northeast</span> on <span class="street">W Mt Pleasant Ave</span>. <span class="distance-description">Go for <span class="length">228 m</span>.</span>, Turn <span class="direction">left</span> onto <span class="next-street">Germantown Ave</span>. <span class="distance-description">Go for <span class="length">19 m</span>.</span>, Go to the stop <span class="station">Germantown Av & Mt Pleasant Av</span> and take the <span class="transit">bus</span> <span class="line">23</span> toward <span class="destination">11th St & Market St -</span>. <span class="distance-description">Follow for <span class="stops">43 stops</span>.</span>, Get off at <span class="station">Germantown Av & Erie Av</span>., Head <span class="heading">east</span> on <span class="street">Germantown Ave</span>. <span class="distance-description">Go for <span class="length">28 m</span>.</span>, Turn <span class="direction">right</span> onto <span class="next-street">W Erie Ave</span>. <span class="distance-description">Go for <span class="length">36 m</span>.</span>, Turn <span class="direction">left</span> onto <span class="next-street">N Broad St</span>. <span class="distance-description">Go for <span class="length">3 m</span>.</span>, Go to the station <span class="station">Erie Station</span> and take the <span class="transit">rail</span> <span class="line">BSL</span> toward <span class="destination">at&T Station</span>. <span class="distance-description">Follow for <span class="stops">15 stations</span>.</span>, Get off at <span class="station">Oregon Station</span>., Head <span class="heading">northeast</span>. <span class="distance-description">Go for <span class="length">10 m</span>.</span>, Turn <span class="direction">slightly left</span> onto <span class="next-street">S Broad St</span>. <span class="distance-description">Go for <span class="length">25 m</span>.</span>, Go to the stop <span class="station">Oregon Av & Broad St</span> and take the <span class="transit">bus</span> <span class="line">68</span> toward <span class="destination">69th St Transportation Center South Terminal</span>. <span class="distance-description">Follow for <span class="stops">16 stops</span>.</span>, Get off at <span class="station">Enterprise Av & Fort Mifflin Rd</span>., Head <span class="heading">northwest</span> on <span class="street">Enterprise Ave</span>. <span class="distance-description">Go for <span class="length">32 m</span>.</span>, Turn <span class="direction">right</span> onto <span class="next-street">Fort Mifflin Rd</span>. <span class="distance-description">Go for <span class="length">1.7 km</span>.</span>, Turn <span class="direction">left</span> onto <span class="next-street">Fort Mifflin Rd</span>. <span class="distance-description">Go for <span class="length">75 m</span>.</span>, Take the street on the <span class="direction">right</span>. <span class="distance-description">Go for <span class="length">734 m</span>.</span>, Arrive at <span class="street">Fort Mifflin Rd</span>., 237, 19, 1770, 0, 41, 46, 3, 1610, 0, 14, 25, 2720, 0, 42, 1723, 76, 740, 0, 228, 19, 6529, 0, 28, 36, 3, 10420, 0, 10, 25, 7864, 0, 32, 1713, 75, 734, 0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13, M14, M15, M16, M17, M18, PrivateTransportManeuverType, PrivateTransportManeuverType, PublicTransportManeuverType, PublicTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PublicTransportManeuverType, PublicTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PublicTransportManeuverType, PublicTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, NA, NA, Germantown Av & Mt Pleasant Av, Germantown Av & Erie Av, NA, NA, NA, Erie Station, Oregon Station, NA, NA, Oregon Av & Broad St, Enterprise Av & Fort Mifflin Rd, NA, NA, NA, NA, NA, NA, NA, NA, Germantown Ave, NA, NA, NA, NA, NA, NA, NA, NA, Enterprise Ave, NA, NA, NA, NA, NA, 40.0568444, 40.0583732, 40.0583732, 40.0094068, 40.0094068, 40.0092137, 40.0092459, 40.0092459, 39.9167848, 39.9167848, 39.9168277, 39.9168277, 39.8836005, 39.8836005, 39.8837721, 39.8775494, 39.8770881, 39.8786749, -75.1911711, -75.189389, -75.189389, -75.1509583, -75.1509583, -75.1508081, -75.1512265, -75.1513124, -75.1714182, -75.1714182, -75.1713324, -75.1713324, -75.2235281, -75.2235281, -75.223335, -75.2135289, -75.2129066, -75.2075897, +18693161, stopOver, 0.3478261, right, W Mt Pleasant Ave, W Mt Pleasant Ave, 0, 40.0568444, -75.1911711, 40.0567437, -75.19102, +18769947, stopOver, 0.4118199, neither, Fort Mifflin Rd, Fort Mifflin Rd, 188, 39.8786749, -75.2075897, 39.8777652, -75.2059473
##                                                                                                                                                                   publicTransportLine
## 1 23, BSL, 68, , , , 11th St & Market St -, at&T Station, 69th St Transportation Center South Terminal, busPublic, railMetro, busPublic, L1, L2, L3, NA, #FF9933, NA, NA, #FF9933, NA
##   mode.type mode.transportModes mode.trafficMode mode.feature
## 1   fastest     publicTransport         disabled         NULL
##   summary.distance summary.baseTime
## 1            27716             9066
##                                   summary.flags
## 1 noThroughRoad, builtUpArea, park, privateRoad
##                                                                               summary.text
## 1 The trip takes <span class="length">27.7 km</span> and <span class="time">2:31 h</span>.
##   summary.travelTime         summary.departure
## 1               9066 2018-07-18T12:00:00-04:00
##                     summary._type
## 1 PublicTransportRouteSummaryType
## 
## $response$language
## [1] "en-us"
```

#### step 4

```r
 final_url_test <- as.data.frame(json_url_test)
```



```
##   response.metaInfo.timestamp response.metaInfo.mapVersion
## 1        2018-07-23T23:08:13Z                  8.30.85.156
##   response.metaInfo.moduleVersion response.metaInfo.interfaceVersion
## 1                7.2.201829-33197                             2.6.34
##   response.metaInfo.availableMapVersion
## 1                           8.30.85.156
##                                                                                                                                                                                                                                            response.route.waypoint
## 1 +18693161, +18769947, stopOver, stopOver, 0.3478261, 0.4118199, right, neither, W Mt Pleasant Ave, Fort Mifflin Rd, W Mt Pleasant Ave, Fort Mifflin Rd, 0, 188, 40.0568444, 39.8786749, -75.1911711, -75.2075897, 40.0567437, 39.8777652, -75.19102, -75.2059473
##                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       response.route.leg
## 1 27716, 9066, Head <span class="heading">northeast</span> on <span class="street">W Mt Pleasant Ave</span>. <span class="distance-description">Go for <span class="length">228 m</span>.</span>, Turn <span class="direction">left</span> onto <span class="next-street">Germantown Ave</span>. <span class="distance-description">Go for <span class="length">19 m</span>.</span>, Go to the stop <span class="station">Germantown Av & Mt Pleasant Av</span> and take the <span class="transit">bus</span> <span class="line">23</span> toward <span class="destination">11th St & Market St -</span>. <span class="distance-description">Follow for <span class="stops">43 stops</span>.</span>, Get off at <span class="station">Germantown Av & Erie Av</span>., Head <span class="heading">east</span> on <span class="street">Germantown Ave</span>. <span class="distance-description">Go for <span class="length">28 m</span>.</span>, Turn <span class="direction">right</span> onto <span class="next-street">W Erie Ave</span>. <span class="distance-description">Go for <span class="length">36 m</span>.</span>, Turn <span class="direction">left</span> onto <span class="next-street">N Broad St</span>. <span class="distance-description">Go for <span class="length">3 m</span>.</span>, Go to the station <span class="station">Erie Station</span> and take the <span class="transit">rail</span> <span class="line">BSL</span> toward <span class="destination">at&T Station</span>. <span class="distance-description">Follow for <span class="stops">15 stations</span>.</span>, Get off at <span class="station">Oregon Station</span>., Head <span class="heading">northeast</span>. <span class="distance-description">Go for <span class="length">10 m</span>.</span>, Turn <span class="direction">slightly left</span> onto <span class="next-street">S Broad St</span>. <span class="distance-description">Go for <span class="length">25 m</span>.</span>, Go to the stop <span class="station">Oregon Av & Broad St</span> and take the <span class="transit">bus</span> <span class="line">68</span> toward <span class="destination">69th St Transportation Center South Terminal</span>. <span class="distance-description">Follow for <span class="stops">16 stops</span>.</span>, Get off at <span class="station">Enterprise Av & Fort Mifflin Rd</span>., Head <span class="heading">northwest</span> on <span class="street">Enterprise Ave</span>. <span class="distance-description">Go for <span class="length">32 m</span>.</span>, Turn <span class="direction">right</span> onto <span class="next-street">Fort Mifflin Rd</span>. <span class="distance-description">Go for <span class="length">1.7 km</span>.</span>, Turn <span class="direction">left</span> onto <span class="next-street">Fort Mifflin Rd</span>. <span class="distance-description">Go for <span class="length">75 m</span>.</span>, Take the street on the <span class="direction">right</span>. <span class="distance-description">Go for <span class="length">734 m</span>.</span>, Arrive at <span class="street">Fort Mifflin Rd</span>., 237, 19, 1770, 0, 41, 46, 3, 1610, 0, 14, 25, 2720, 0, 42, 1723, 76, 740, 0, 228, 19, 6529, 0, 28, 36, 3, 10420, 0, 10, 25, 7864, 0, 32, 1713, 75, 734, 0, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13, M14, M15, M16, M17, M18, PrivateTransportManeuverType, PrivateTransportManeuverType, PublicTransportManeuverType, PublicTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PublicTransportManeuverType, PublicTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PublicTransportManeuverType, PublicTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, PrivateTransportManeuverType, NA, NA, Germantown Av & Mt Pleasant Av, Germantown Av & Erie Av, NA, NA, NA, Erie Station, Oregon Station, NA, NA, Oregon Av & Broad St, Enterprise Av & Fort Mifflin Rd, NA, NA, NA, NA, NA, NA, NA, NA, Germantown Ave, NA, NA, NA, NA, NA, NA, NA, NA, Enterprise Ave, NA, NA, NA, NA, NA, 40.0568444, 40.0583732, 40.0583732, 40.0094068, 40.0094068, 40.0092137, 40.0092459, 40.0092459, 39.9167848, 39.9167848, 39.9168277, 39.9168277, 39.8836005, 39.8836005, 39.8837721, 39.8775494, 39.8770881, 39.8786749, -75.1911711, -75.189389, -75.189389, -75.1509583, -75.1509583, -75.1508081, -75.1512265, -75.1513124, -75.1714182, -75.1714182, -75.1713324, -75.1713324, -75.2235281, -75.2235281, -75.223335, -75.2135289, -75.2129066, -75.2075897, +18693161, stopOver, 0.3478261, right, W Mt Pleasant Ave, W Mt Pleasant Ave, 0, 40.0568444, -75.1911711, 40.0567437, -75.19102, +18769947, stopOver, 0.4118199, neither, Fort Mifflin Rd, Fort Mifflin Rd, 188, 39.8786749, -75.2075897, 39.8777652, -75.2059473
##                                                                                                                                                    response.route.publicTransportLine
## 1 23, BSL, 68, , , , 11th St & Market St -, at&T Station, 69th St Transportation Center South Terminal, busPublic, railMetro, busPublic, L1, L2, L3, NA, #FF9933, NA, NA, #FF9933, NA
##   response.route.mode.type response.route.mode.transportModes
## 1                  fastest                    publicTransport
##   response.route.mode.trafficMode response.route.mode.feature
## 1                        disabled                        NULL
##   response.route.summary.distance response.route.summary.baseTime
## 1                           27716                            9066
##                    response.route.summary.flags
## 1 noThroughRoad, builtUpArea, park, privateRoad
##                                                                response.route.summary.text
## 1 The trip takes <span class="length">27.7 km</span> and <span class="time">2:31 h</span>.
##   response.route.summary.travelTime response.route.summary.departure
## 1                              9066        2018-07-18T12:00:00-04:00
##      response.route.summary._type response.language
## 1 PublicTransportRouteSummaryType             en-us
```
###

###Preparing Looping Functions for Parallel



```r
#gets the Data from HERE API

get_city = foreach(i=urls, .packages='httr') %dopar% {
    GET(i)
  }

status_code(results[[1]]) #Can check some to ensure it worked

#Gets the Json Content
content_city = foreach(i=get_city, .packages='httr') %dopar% {
  content(i, "text")
}

##munging
#makes the json data semi pretty
json_city = foreach(i=content_city, .packages='jsonlite') %dopar% {
  fromJSON(i, flatten = TRUE)
}

df_city = foreach(i=json_city) %dopar% {
    as.data.frame(i)
  }


full <- rbindlist(df_city, fill = TRUE)
```

###Plan of Attack
To solve my 2nd large issue, I decided to leverage the resources of my university. Generally, the idea is to split up the urls into multiple lists, then run each set of URLs independently on several computers.

To split up the URLs:

```r
list_of_URLs <- split(urls, ceiling(seq_along(urls)/15000))
str(list_of_URLs)
```

```
## List of 6
##  $ 1: chr [1:15000] "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.9813196638719%2C-75.1550982929894&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.9813196638719%2C-75.1550982929894&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.9813196638719%2C-75.1550982929894&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.9813196638719%2C-75.1550982929894&w"| __truncated__ ...
##  $ 2: chr [1:15000] "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0432636793725%2C-75.0445300255391&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0432636793725%2C-75.0445300255391&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0432636793725%2C-75.0445300255391&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0432636793725%2C-75.0445300255391&w"| __truncated__ ...
##  $ 3: chr [1:15000] "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.8874807526335%2C-75.1786084661623&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.8874807526335%2C-75.1786084661623&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.8874807526335%2C-75.1786084661623&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.8874807526335%2C-75.1786084661623&w"| __truncated__ ...
##  $ 4: chr [1:15000] "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0173693479674%2C-75.1183322460106&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0173693479674%2C-75.1183322460106&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0173693479674%2C-75.1183322460106&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0173693479674%2C-75.1183322460106&w"| __truncated__ ...
##  $ 5: chr [1:15000] "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.969074911985%2C-75.2611177652973&wa"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.969074911985%2C-75.2611177652973&wa"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.969074911985%2C-75.2611177652973&wa"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=39.969074911985%2C-75.2611177652973&wa"| __truncated__ ...
##  $ 6: chr [1:14700] "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0451029062209%2C-75.1925423292864&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0451029062209%2C-75.1925423292864&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0451029062209%2C-75.1925423292864&w"| __truncated__ "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0451029062209%2C-75.1925423292864&w"| __truncated__ ...
```

Then on each computer I would run the code, but first specify:

```r
urls<- list_of_URLs[[2]] #insert whatever subset you want to use
str(urls)
```

```
##  chr [1:15000] "https://route.cit.api.here.com/routing/7.2/calculateroute.json?waypoint0=40.0432636793725%2C-75.0445300255391&w"| __truncated__ ...
```

This worked magically. I used several computers over 3 days and got all the data I need. The internet and books constantly preached that 80% of these tasks are data collection / wrangling and only 20% was the actual analysis. I think I finally understand what they mean...But now for the fun! The conclusions and results!!!







*****
[^1]: status codes starting 3xx or 4xx spell out trouble. Also, can use the httr function `status_code()` to get this piece of information easier.




