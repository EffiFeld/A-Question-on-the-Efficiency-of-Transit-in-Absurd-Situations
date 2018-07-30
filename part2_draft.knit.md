#Part 2: Shapefiles and Progress

The main lesson from part 1 is that I'm going to have to be a little less lazy in this project. The minitua is that I needed:
 
   1. a way to graph only the city limits itself  
   2.  a way to generate random points within that irregular polygon

Googling told me that what I needed was a shapefile, "The shapefile format is a popular geospatial vector data format for geographic information system (GIS) software...The shapefile format can spatially describe vector features: points, lines, and polygons, representing, for example, water wells, rivers, and lakes."[^1]

At first, it looked like this required me to download a bunch of files from the internet and load them all into R. At first because of the blessed package Tigris which allows users to download shapefiles from the US Census Bureau.

The below code is using the TIGRIS package to grab the files for Philadelphia, New York City, and Washington D.C.




























