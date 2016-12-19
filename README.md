<a name="top"></a>An R package for property extraction and analysis of multiple Sensing Layers
====

* [Property Extraction](#property-extraction)
 * [Spatial Coverage](#spatial-coverage---spcoverage)
 * [Temporal Coverage](#temporal-coverage---tpcoverage)
 * [Spatial Distribution](#spatial-distribution---spdistribution)
* [Analysis](#analysis)

# Property Extraction

### Spatial Coverage - `spCoverage()`

This property represents the area the data is inserted into. The function `spCoverage()` receives the longitude and latitude columns and returns the extreme coordinates (maximum and minimum), forming a bounding box.

#### Parameters
- **lon:** longitude column
- **lat:** latitude column
- **plotBbox:** if TRUE, it plots the bounding box (default is FALSE)
- **colourBbox:** the colour of the bounding box (default is black)
- **plotData:** if TRUE, it also plots the data as points (default is FALSE)
- **colourData:** the colour of the points (default is yellow)
- **source:** Source of the basemap. It can be Google Maps ("google"), which is the default, OpenStreetMap ("osm") or Stamen Maps ("stamen")
- **maptype:** Character string providing map theme, which depends on the source (default is "terrain")
- **zoom:** Map zoom (leave it NULL for auto zoom)

#### Example
Before anything we should source the file and any dataset.
```
source("POC.R")
ig <- read.table("data/instagram.dat", header=TRUE, stringsAsFactors=FALSE)
```

**1. `spCoverage(ig$lon, ig$lat)` returns:**
```
‏     left   bottom     right       top
-74.06077 40.63317 -73.76324  40.84902
```
**2. `spCoverage(ig$lon, ig$lat, TRUE)` returns:**

<a href="/img/spCoverage1.png"><img src="/img/spCoverage1.png" height="350"></a>

**3. `spCoverage(ig$lon, ig$lat, plotBbox=TRUE, plotData=TRUE, source="stamen")` returns:**

<a href="/img/spCoverage2.png"><img src="/img/spCoverage2.png" height="350"></a>

**4. `spCoverage(ig$lon, ig$lat, TRUE, "red", TRUE, "green", source="stamen",maptype="toner-background")` returns:**

<a href="/img/spCoverage3.png"><img src="/img/spCoverage3.png" height="350"></a>

It is also possible to plot the spatial coverage of multiple layers using `spCoverageList()`. The input is a list with named dataframes. It is important that every df has a lon and lat columns.

```
source("POC.R")
ig <- read.table("data/instagram.dat", header=TRUE, stringsAsFactors=FALSE)
ci <- read.table("data/checkin1.dat", header=TRUE, stringsAsFactors=FALSE)
list <- list(instagram=ig,checkin=ci)
spCoverageList(list, source="stamen")
```
<a href="/img/spCoverage4.png"><img src="/img/spCoverage4.png" height="350"></a>

<a href="#top"><img align="right" src="/img/backtotop.png" width=20></a>

### Temporal Coverage - `tpCoverage()`

This property represents the temporal interval the data is inserted into. The function `spCoverage()` extracts the range from a timestamp (POSIX*) column and returns a vector with the earliest and latest data. It can also return the extent of the interval, if `printDiff` is set as TRUE.

#### Parameters
- **column:** timestamp column
- **printDiff:** if TRUE, it prints the time difference (default is FALSE)

#### Example
Before anything we should source the file and any dataset. We also need to convert the timestamp column to a POSIXct or POSIXlt format, since originaly its class is character.

```
source("POC.R")
ig <- read.table("data/instagram.dat", header=TRUE, stringsAsFactors=FALSE)
ig$timestamp <- as.POSIXct(ig$timestamp, format="%Y-%m-%dT%H:%M:%SZ")
```
**1.** `tpCoverage(ig$timestamp)` returns:

```
[1] "2013-05-11 12:34:20 BRT" "2013-05-25 01:23:34 BRT"
```

**2.** `tpCoverage(ig$timestamp, TRUE)` returns:
```
Time difference of 13.53419 days
[1] "2013-05-11 12:34:20 BRT" "2013-05-25 01:23:34 BRT"
```
<a href="#top"><img align="right" src="/img/backtotop.png" width=20></a>

### Spatial Distribution - `spDistribution()`
This property returns the percentage of the spatial coverage that has data associated with. It first divides the space into rectangles and creates a matrix to represent it. Then it process all the data points, checking in which rectangle each point is inserted into. It then returns the percentage of rectangles with data. It can also return a plot with the data rectangles coloured.

<a href="/img/spDistribution1.png"><img src="/img/spDistribution1.png" height="350"></a>

#### Parameters
- **lon:** Longitude column
- **lat:** Latitude column
- **nx:** Number of horizontal rectangles the area will be divided into
- **ny:** Number of vertical rectangles the area will be divided into
- **plot:** TRUE to plot the rectangles with data (default is FALSE)
- **col:** Colour of the plot (default is "red")
- **source:** Source of the basemap. It can be Google Maps ("google"), which is the default, OpenStreetMap ("osm") or Stamen Maps ("stamen")
- **maptype:** Character string providing map theme, which depends on the source (default is "terrain")

#### Example

```
source("POC.R")
ig <- read.table("data/instagram.dat", header=TRUE, stringsAsFactors=FALSE)
```
Using the ggmap's crime dataset, `spDistribution(crime$lon,crime$lat,20,20,plot=TRUE)`, we can see that the data is inserted into only 3.75% of the spatial coverage.

<a href="/img/spDistribution2.png"><img src="/img/spDistribution2.png" height="350"></a>

We can also see that the more we increase the resolution, i.e., the number of horizontal and vertical rectangles (nx and ny), the more precise it gets. The pictures bellow divide the same layer into 100 and 2500 rectangles, returning 98% and 61.96%, respectively.

`spDistribution(ig$lon,ig$lat,10,10,plot=TRUE, source="stamen")`

<a href="/img/spDistribution3.png"><img src="/img/spDistribution3.png" height="350"></a>

`spDistribution(ig$lon,ig$lat,50,50,plot=TRUE, source="stamen")`

<a href="/img/spDistribution4.png"><img src="/img/spDistribution4.png" height="350"></a>

<a href="#top"><img align="right" src="/img/backtotop.png" width=20></a>
# Analysis
1. [STIA](https://github.com/FdeFabricio/POC/tree/master/tutorials/STIA)
