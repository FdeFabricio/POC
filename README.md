<a name="top"></a>An R package for property extraction and analysis of multiple Sensing Layers
====

* [Property Extraction](#property-extraction)
 * [Spatial Coverage](#spatial-coverage---spcoverage)
 * [Temporal Coverage](#temporal-coverage---tpcoverage)
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

# Analysis
1. [STIA](https://github.com/FdeFabricio/POC/tree/master/tutorials/STIA)
