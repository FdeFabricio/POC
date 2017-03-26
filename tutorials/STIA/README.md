# STIA: SpatioTemporal Intersection Analysis

## Introduction

Let’s say we have a hypothesis. We believe that temperature influences on where people like to go in a city. For example area A is really popular when it’s warm because there are parks or open-air pubs; area B, on the other hand, is most popular when it’s chilly. As area A is busier during summer, we assume the level of noise increases as well, right?

So, what we should do is try to correlate temperature, noise level and place popularity in order to test our hypothesis. For this matter, we need at least three different datasets: temperature, noise level and popularity. In this example we are using Weather Underground (temperature), Noise Tube (noise level), geolocated check-ins and posts on Instagram (place popularity) as data sources. Each one of these will become a different sensing layer.

**But if we want to measure how one variable correlates to another we shall, first, test if the data has spatial and temporal intersection.** It would be a mistake trying to correlate London’s temperature with Munich’s noise level. “Oh right, when it’s really cold in London, the Germans like to shout on the streets.” The same if we correlated temperature from the 80’s with check-ins from 2016. Basically, we need to make sure the sensing layers belong to the same area (to the same city, for instance) and to the same time. That’s why we need the SpatioTemporal Intersection Analysis (STIA).

## Prerequisites

For this tutorial, we are going to use four Sensing Layers: temperature, noise level, check-ins and Instagram posts. Hence the following files will be needed and can be found in [this repository](https://github.com/FdeFabricio/POC/tree/master/Tutorial/src):

```
checkin.dat
instagram.dat
noisetube.csv
weatherunderground.csv
```

## Load the files

Only after loading the file `POC.R` we will be able to access all functions implemented on the tool, indispensable to execute any extraction or analysis.

```
# load the main file
source("../../POC.R")
```
Now we need to load all datasets we are going to use for this tutorial. Each one is in a separate file. A couple of files contain a header, the others don't. It depends entirely on the datasets you will be working, so feel free to load data frames as you please.

```
# load the data frames
ig <- read.table("../src/instagram.dat", header=FALSE, stringsAsFactors=FALSE)
ci <- read.table("../src/checkin.dat", header=FALSE, stringsAsFactors=FALSE)
wu <- read.csv("../src/weatherunderground.csv", header=TRUE, stringsAsFactors=FALSE)
nt <- read.csv("../src/noisetube.csv", header=TRUE, stringsAsFactors=FALSE)
```

All of this data frames contain a timestamp column. But if you check using Instagram data frame, for instance, you can see that the class isn't compatible with Date-Time. `str(ig)` returns:
```
'data.frame':    50382 obs. of  7 variables:
 $ V1: int  18809563 14411317 43075363 189700747 33229978 31086370 61759008 233334335 28364791 358787407 ...
 $ V2: chr  "2013-05-11T12:34:20Z" "2013-05-11T12:35:33Z" "2013-05-11T12:37:12Z" "2013-05-11T12:38:01Z" ...
 $ V3: num  40.7 40.6 40.8 40.7 40.7 ...
 $ V4: num  -74 -73.8 -74 -74 -74 ...
 $ V5: chr  "40.695-74.0133" "40.6451-73.7845" "40.7556-73.9874" "40.7218-74.0008" ...
 $ V6: chr  "en" "en" "en" "en" ...
 $ V7: chr  "instagram.com/p/ZK-8lsgL-P/" "instagram.com/p/ZK--wnSkAg/" "instagram.com/p/ZK_MpRBjh1/" "instagram.com/p/ZK_O6EvJ7_/" ...
```
 `ig$V2` is the column which contains the timestamp of each post, and its class is character. Therefore we need to convert the column to [POSIXct (or POSIXlt)](https://stat.ethz.ch/R-manual/R-devel/library/base/html/as.POSIXlt.html). Use `str()` to check which column of each data frame you need to convert.

 ```
# convert the datetime column into the correct class/type
ig$V2 <- as.POSIXct(ig$V2, format="%Y-%m-%dT%H:%M:%SZ")
ci$V2 <- as.POSIXct(ci$V2, format="%Y-%m-%dT%H:%M:%SZ")
wu$EST <- as.POSIXct(wu$EST, format="%Y-%m-%d", "UTC")
nt$made_at <- as.POSIXct(nt$made_at, format="%Y-%m-%dT%H:%M:%SZ")
```
Now we are ready to make the analysis we want :)

_P.S.: you can note that the ig's and ci's columns have automatically generated names (V1, V2...). You can add names to the columns or add header to the files before loading them, so you make the process easier to follow._

## Executing the analysis

The STIA can receive two parameters. For temporal intersection, you need to inform a list of all timestamp columns. For spatial it requires a list of a list. The latter has the latitude and longitude columns of each data frame. Both are not required, hence you can run only temporal intersection analysis if you want.

```
tempList <- list(checkin=ci$V2, instagram=ig$V2, weatherUn=wu$EST, noiseTube=nt$made_at)
spatList <- list(checkin=list(lat=ci$V3,lon=ci$V4),instagram=list(lat=ig$V3,lon=ig$V4), noiseTube=list(lat=nt$lat, lon=nt$lng))
```

Note that the temperature layer isn't included in the spatial intersection analysis. It is so because the original dataset didn't have geometry data. But there is an option [when your layer doesn't have a geom column](#whenyour).

Now we just run the analysis and that's it.

```
STIA(T=tempList, S=spatList)
```

## Interpreting the results

The STIA output is two matrix representing the combinatory intersection. Each element **M(i,j)** represent the percentage of intersection between **i** and **j** over original **i**. For instance, Temporal(2,1) = 0.99999316 says that the intersection between instagram and checkin data represents 99.999316% of instagram temporal coverage.

```
$temporal
             checkin  instagram weatherUn noiseTube
checkin   1.00000000 0.99992646         1         0
instagram 0.99999316 1.00000000         1         0
weatherUn 0.03718432 0.03718184         1         0
noiseTube 0.00000000 0.00000000         0         1

$spatial
            checkin instagram noiseTube
checkin   1.0000000 0.9965368         0
instagram 0.9989773 1.0000000         0
noiseTube 0.0000000 0.0000000         1
```

 M(i,j) ∈ [0,1]. When equal to zero, it means there is no intersection. When equal to 1, it means the intersection is equal to i.

### Spatial


### Temporal

Analysing temporal data we can see that checkin and instagram are really close since their intersection is almost total. If we use `tpCoverage()` function to calculate the temporal coverage of both we notice that checkin data goes from "2013-05-11 12:32:54 BRT" to "2013-05-25 01:23:26 BRT" and instagram's goes from "2013-05-11 12:34:20 BRT" to "2013-05-25 01:23:34 BRT". I.e., there is only a difference in minutes between these two data frames, hence so close to 1.

Temporal(1,3) = Temporal(2,3) = 1 means that the weatherUn intersects the entire temporal dimension of checkin and instagram data. On the other hand, the last two represents only 3.7% of weatherUn temporal coverage, see Temporal(3,1) and Temporal(3,2). WeatherUn data covers the entire year of 2013.

Finally, noiseTube doesn't intersect anyone of the other three since its data is from 2015 only.

## Conclusion

## Appendix

### <a id="whenyour"></a>When your layer doesn't have a geom column
