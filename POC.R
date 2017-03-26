library(ggmap)
library(rgeos)
library(raster)
library(plyr)
library(scales)

#' Spatial Coverage.
#'
#' \code(spCoverage) returns the spatial coverage of a given layer
#'
#' This property represents the area the data is inserted into. It receives the
#' longitude and latitude columns and returns the extreme coordinates (maximum
#' and minimum), forming a bounding box.
#'
#' @param lon Longitude column
#' @param lat Latitude column
#' @param plotBbox If TRUE it plots the bounding box
#' @param colourBbox Colour of the bounding box
#' @param plotData If TRUE it also plots the data as points
#' @param colourBbox Colour of data points
#' @param source Google Maps ("google"), OpenStreetMap ("osm") or Stamen Maps ("stamen")
#' @param maptype Character string providing map theme, which depends on the source
#' @param zoom Map zoom (leave it NULL for auto zoom)
#' @return The output is a bounding box. This function can also plot the bounding box and data points on a base map.
spCoverage <- function(lon, lat, plotBbox=FALSE, colourBbox="black", plotData=FALSE, colourData="yellow", source="google", maptype="terrain", zoom=NULL)
{
  bbox <- make_bbox(lon, lat, f=0)
  if (plotBbox == FALSE)
  {
    return(bbox)
  }
  print(bbox)

  # Plotting
  myMap <- getBaseMap(source, maptype, bbox, zoom)
  dataPlot <- geom_blank()
  areaPlot <- geom_polygon(aes(x=x, y=y), data=bboxToPolygon(bbox), colour=colourBbox, fill=colourBbox, alpha=.4, size=.3)
  if (plotData == TRUE)
  {
    dataPlot <- geom_point(aes(x=lon, y=lat),  data=data.frame(lon,lat), size=.3, colour=colourData)
  }
  ggmap(myMap,extent="device")+ggtitle("\nSpatial Coverage")+theme(plot.title=element_text(hjust = 0.5))+areaPlot+dataPlot
}

#' Multiple Spatial Coverage
#'
#' \code(spCoverageList) returns the spatial coverage of a list of layers
#'
#' @param list List with the layers
#' @param source Google Maps ("google"), OpenStreetMap ("osm") or Stamen Maps ("stamen")
#' @param maptype Character string providing map theme, which depends on the source
#'
#' @return A plot with each individual spatial coverage on a base map
#'
#' @examples
#' list <- list(instagram=list,checkin=ci)
#' spCoverageList(list, source="stamen")
spCoverageList <- function(list, source="google", maptype="terrain")
{
  # stores all the bbox coordinates from all layers to plot a map with the extreme coordinates
  coord <- list(lon=c(),lat=c())

  # stores all polygons (bboxes)
  polygon <- list()

  for (i in 1:length(list))
  {
    df <- list[[i]]

    bbox <- spCoverage(df$lon, df$lat)

    coord$lon <- append(coord$lon, bbox[c(1,3)])
    coord$lat <- append(coord$lat, bbox[c(2,4)])

    polygonDF <- bboxToPolygon(bbox)
    polygonDF$name <- names(list)[i]

    polygon[[i]] <- geom_polygon(aes(x=x,y=y,fill=name,color=name), data=polygonDF, alpha=.5, size=.4)
  }

  myLocationBbox <- make_bbox(coord$lon, coord$lat, f=0.1)
  zoom <- calc_zoom(myLocationBbox)

  if(source == "google") myMap <- get_googlemap(center=getCentre(bbox), zoom=zoom-1, maptype=maptype)
  else if(source == "stamen") myMap <- get_stamenmap(myLocationBbox, zoom=zoom, maptype=maptype, crop=TRUE)
  else if(source == "osm") myMap <- get_map(myLocationBbox, zoom=zoom, source="osm")

  ggmap(myMap,extent="device")+polygon+theme(legend.position="bottom",legend.title=element_blank(),plot.title=element_text(hjust = 0.2))
}

#' Temporal Coverage.
#'
#' \code(tpCoverage) returns the temporal coverage of a given dataframe.
#'
#' @param column Column with timestamp data.
#' @param printDiff If TRUE prints also the date range difference.
#'
#' @return A two element vector with the first and last timestamp (earliest and latest).
#'
#' @examples
#' randomTimestamps <- as.POSIXct(runif(100,946684800,as.numeric(Sys.time())), origin="1970-1-1")
#' tpCoverage(randomTimestamps)
#' tpCoverage(randomTimestamps,TRUE)
tpCoverage <- function(column, printDiff=FALSE)
{
  x <- getExtremes(column)
  if(printDiff) print(x[2]-x[1])
  return(x)
}

#' Spatial Distribution
#'
#' \code{spDistribution} returns the percentage of the spatial coverage that has data in it
#'
#' @param lon Longitude column
#' @param lat Latitude column
#' @param nx Number of horizontal rectangles the area will be divided into
#' @param ny Number of vertical rectangles the area will be divided into
#' @param plot TRUE to plot the rectangles with data
#' @param col Colour of the plot
#' @param source Google Maps ("google"), OpenStreetMap ("osm") or Stamen Maps ("stamen")
#' @param maptype Character string providing map theme, which depends on the source
#'
#' @return percentage of area covered by data and plot (optional)
#' @examples
#' spDistribution(crime$lon,crime$lat,20,20,plot=TRUE,source="google")
spDistribution <- function(lon, lat, nx, ny, plot=FALSE, col="red", source="google", maptype="terrain")
{
  lon <- na.omit(lon)
  lat <- na.omit(lat)

  stopifnot(length(lon) == length(lat))

  bbox <- make_bbox(lon,lat,f=0)
  minX <- bbox[1]
  minY <- bbox[2]
  maxX <- bbox[3]
  maxY <- bbox[4]

  # Matrix with all the individual rectangles
  m <- matrix(0,nrow=nx,ncol=ny)

  # The distance between rectangles (its size, basically)
  xStep <- abs(maxX-minX)/nx
  yStep <- abs(maxY-minY)/ny

  # For each point of the dataframe, convert cartesian coordinates (x,y) to matrix coordinates (a,b) and set m[a,b]
  # m[a,b] = 1 means there is at least a point inside that rectangle
  # m[a,b] = 0 means there is no point inside that rectangle
  for (i in 1:length(lon))
  {
    if(is.na(lon[i])||is.na(lat[i])) next

    a <- floor(abs((lon[i]-minX)/xStep))+1
    b <- floor(abs((lat[i]-minY)/yStep))+1

    if((a<=nx)&(b<=ny))
    {
      m[a,b] <- 1
    }
  }

  print(sum(m)/(nx*ny))

  if (plot == TRUE)
  {
    # raster plot
    r <- raster(xmn=minX, ymn=minY, xmx=maxX, ymx=maxY, nrows=nx, ncols=ny)
    r[] <- 0
    xy <- SpatialPoints(cbind(lon,lat))
    tab <- table(cellFromXY(r, xy))
    r[as.numeric(names(tab))] <- 1

    breakpoints <- c(0,0.5,1)
    colors <- c(adjustcolor("white",alpha.f=0),adjustcolor(col,alpha.f=0.7))
    rasterPlot <- as.raster(r,breaks=breakpoints,col=colors)

    # basemap
    myMap <- getBaseMap(source, maptype, bbox)

    # generate plot
    bboxPlot <- geom_polygon(aes(x=x, y=y), data=bboxToPolygon(bbox), colour = col, fill = NA)
    ggmap(myMap,extent="device")+inset_raster(rasterPlot,xmin=bbox(r)[1,1],ymin=bbox(r)[2,1],xmax=bbox(r)[1,2],ymax=bbox(r)[2,2])+bboxPlot
  }
}

#' Temporal Distribution
#'
#' \code{tpDistribution} returns the percentage of the complete interval (temporal coverage) that has data in it
#'
#' @param column Column with timestamp data
#' @param res Time resolution: "yearly", "montly", "daily", "hourly", "minutely" or "secondly"
#' @param verbose if TRUE it returns also the two dataframes with the data intervals
#'
#' @return A percentage of how much of the time coverage is covered by data
tpDistribution <- function(column, res, verbose=FALSE)
{
  coverage <- tpCoverage(column)
  # nTotal = intervals (according to the resolution) between the timestamp extremes
  # nData = intervals that has data
  if(res == "yearly")
  {
    coverage <- as.POSIXlt(paste(format(coverage,"%Y"),"1-1",sep="-"))
    nTotal <- length(seq(from=coverage[1],to=coverage[2],by="1 year"))
    nData <- groupFrequency(column,by=c("year"))
  }
  else if(res == "monthly")
  {
    coverage <- as.POSIXlt(paste(format(coverage,"%Y-%m"),"1",sep="-"))
    nTotal <- seq(from=coverage[1],to=coverage[2],by="1 month")
    nData <- groupFrequency(column,by=c("year","mon"))
  }
  else if (res == "daily")
  {
    coverage <- as.POSIXlt(format(coverage,"%Y-%m-%d"))
    nTotal <- seq(from=coverage[1],to=coverage[2],by="1 day")
    nData <- groupFrequency(column,by=c("year","mon","mday"))
  }
  else if(res == "hourly")
  {
    coverage <- as.POSIXlt(paste(format(coverage,"%Y-%m-%d %H"),"00:00",sep=":"))
    nTotal <- seq(from=coverage[1],to=coverage[2],by="1 hour")
    nData <- groupFrequency(column,by=c("year","mon","mday","hour"))
  }
  else if(res == "minutely")
  {
    coverage <- as.POSIXlt(paste(format(coverage,"%Y-%m-%d %H:%M"),"00",sep=":"))
    nTotal <- seq(from=coverage[1],to=coverage[2],by="1 min")
    nData <- groupFrequency(column,by=c("year","mon","mday","hour","min"))
  }
  else if(res == "secondly")
  {
    nTotal <- seq(from=coverage[1],to=coverage[2],by="1 sec")
    nData <- groupFrequency(column,by=c("year","mon","mday","hour","min","sec"))
  }
  if(!verbose) return(tpDistribution=nrow(nData)/length(nTotal))
  else return(list(tpDistribution=(nrow(nData)/length(nTotal)),totalIntervals=nTotal,dataIntervals=nData))
}

#' Refresh Rate
#'
#' \code{refreshRate} returns the arithmetic mean of the time difference between consecutive measurements, giving the mean refreshRate
#'
#' @param timestamp Column with the timestamp data
#' @param by Vector with the parameters to group the data by time frames ("year","mon","mday","hour",min","sec","wday","yday"). Default is NULL which doesn't group the data
#' @param verbose TRUE to also return the dataframe of the extraction which can be used in a plot
#'
#' @return Arithmetic mean, standard deviation and coefficient of variation of the refresh rate
refreshRate <- function(timestamp, by=NULL, verbose=FALSE)
{
  timestamp <- sort(timestamp)

  sec <- as.POSIXlt(timestamp)$sec
  min <- as.POSIXlt(timestamp)$min
  hour <- as.POSIXlt(timestamp)$hour
  mday <- as.POSIXlt(timestamp)$mday
  mon <- as.POSIXlt(timestamp)$mon
  year <- as.POSIXlt(timestamp)$year
  wday <- weekdays(timestamp)
  yday <- as.POSIXlt(timestamp)$yday

  mon <- mon+1
  year <- year+1900
  yday <- yday+1

  df <- data.frame(timestamp,year,mon,mday,hour,min,sec,wday,yday)
  df$diff <- c(diff(timestamp, units="secs"),NA)
  df <- head(df,-1)

  if(is.null(by))
  {
    mean <- mean(df$diff)
    sd <- sd(df$diff)
    cv <- cv(df$diff)
  }
  else
  {
    # indexes to ignore when calculating the mean(diff)
    index <- (as.numeric(rownames(unique(df[by])))-1)[-1]
    df <- df[-index,]
    mean <- ddply(df, by, summarize, mean=mean(diff))
    sd <- ddply(df, by, summarize, sd=sd(diff))
    cv <- ddply(df, by, summarize, cv=cv(diff))
  }
  if(!verbose) return(list(mean=mean,sd=sd,cv=cv))
  else return(list(mean=mean,sd=sd,cv=cv,df=df))
}

#' Spatial Popularity
#'
#' \code{spPopularity} returns a map highlighting areas with high data density
#'
#' @param lon Longitude column
#' @param lat Latitude column
#' @param source Google Maps ("google"), OpenStreetMap ("osm") or Stamen Maps ("stamen")
#' @param maptype Character string providing map theme, which depends on the source
#' @param colHigh Colour of the high density area
#' @param colLow Colour of the low density area
#' @param hideMap TRUE to only plot the popularity without the background map
#'
#' @return Map with the density of points, pointing out popular areas
spPopularity <- function(lon, lat, source="google", maptype="terrain", colHigh="red",colLow="yellow",hideMap=FALSE)
{
  df <- data.frame(lon,lat)
  bbox <- make_bbox(lon, lat, f=0)

  if(hideMap) basePlot <- ggplot()
  else basePlot <- ggmap(getBaseMap(source,maptype,bbox))

  basePlot+
    stat_density2d(aes(lon,lat,fill=..level..,alpha=..level..), data=df, geom="polygon", alpha = 0.4)+
    scale_fill_gradient(high=colHigh,low=colLow)+
    scale_alpha(range=c(0, 0.3), guide=FALSE)+
    geom_density2d(aes(lon,lat),data=df,size=0.2,alpha=0.3)+
    labs(x="Longitude", y="Latitude")+
    ggtitle("Spatial Popularity")+
    theme(plot.title=element_text(hjust = 0.5))
}

#' Temporal Popularity
#'
#' \code{tpPopularity} returns a dataframe that asserts which periods of time are more popular than others
#'
#' @param timestamp Column with the timestamp data
#' @param by Vector with the parameters to group the data by time frames ("year","mon","mday","hour",min","sec","wday","yday")
#'
#' @return Dataframe with each grouped period of time and the number of data is included in it (count)
tpPopularity <- function(timestamp,by)
{
  if (is.element("sec",by)) sec <- as.POSIXlt(timestamp)$sec
  else sec <- NULL

  if (is.element("min",by)) min <- as.POSIXlt(timestamp)$min
  else min <- NULL

  if (is.element("hour",by)) hour <- as.POSIXlt(timestamp)$hour
  else hour <- NULL

  if (is.element("mday",by)) mday <- as.POSIXlt(timestamp)$mday
  else mday <- NULL

  if (is.element("mon",by)) mon <- as.POSIXlt(timestamp)$mon+1
  else mon <- NULL

  if (is.element("year",by)) year <- as.POSIXlt(timestamp)$year+1900
  else year <- NULL

  if (is.element("wday",by)) wday <- as.POSIXlt(timestamp)$wday+1
  else wday <- NULL

  if (is.element("yday",by)) yday <- as.POSIXlt(timestamp)$yday+1
  else yday <- NULL

  t <- newTimestamp(year,mon,mday,hour,min,sec,wday,yday)
  df <- data.frame(t)
  df$count <- 1

  if (is.element("wday",by))
  {
    df$wday <- as.POSIXlt(df$t)$wday
    result <- aggregate(df$count, by=list(df$t,df$wday), FUN=sum)
    names(result) <- c("timestamp","wday","count")
    weekdays <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
    result$wday <- weekdays[result$wday+1]
    return(result)
  }
  result <- aggregate(df$count, by=list(df$t), FUN=sum)
  names(result) <- c("timestamp","count")
  return(result)
}

# STIA
STIA <- function(T=NULL,S=NULL)
{
  result <- list()
  # Generate Temporal Matrix
  n <- length(T)
  if (n > 1)
  {
    resultT <- matrix(nrow=n, ncol=n)
    colnames(resultT) <- names(T)
    rownames(resultT) <- names(T)

    for (i in 1:n)
    {
      for (j in 1:n)
      {
        if (i != j)
        {
          resultT[i,j] <- tempotalIntersection(a=T[[i]],b=T[[j]])
        }
        else
        {
          resultT[i,j] <- 1
        }
      }
    }
    result[["temporal"]] <- resultT
  }

  # Generate Spatial Matrix
  n <- length(S)
  if (n > 1)
  {
    resultS <- matrix(nrow=n, ncol=n)
    colnames(resultS) <- names(S)
    rownames(resultS) <- names(S)

    for (i in 1:n)
    {
      for (j in 1:n)
      {
        if (i != j)
        {
          resultS[i,j] <- spatialIntersection(lonA=S[[i]][["lon"]], latA=S[[i]][["lat"]], lonB=S[[j]][["lon"]], latB=S[[j]][["lat"]])
        }
        else
        {
          resultS[i,j] <- 1
        }
      }
    }
    result[["spatial"]] <- resultS
  }
  return(result)
}

tempotalIntersection <- function(a, b)
{
  extreme.a <- tpCoverage(a)
  extreme.b <- tpCoverage(b)

  if ((extreme.a[1]>extreme.b[1] && extreme.a[1]>extreme.b[2])||(extreme.a[2]<extreme.b[1] && extreme.a[2]<extreme.b[2]))
  {
    return(0)
  }

  if (extreme.a[1]-extreme.b[1] >= 0) result1 = extreme.a[1]
  else result1 = extreme.b[1]

  if (extreme.b[2]-extreme.a[2] >= 0) result2 = extreme.a[2]
  else result2 = extreme.b[2]

  return(as.numeric(result2-result1)/as.numeric(extreme.a[2]-extreme.a[1]))
}

spatialIntersection <- function(lonA, lonB, latA, latB)
{
  coordA <- spCoverage(lon=lonA, lat=latA)
  coordB <- spCoverage(lon=lonB, lat=latB)

  polygonA <- readWKT(paste("POLYGON((",as.character(coordA$lonR[1])," ",as.character(coordA$latR[1]),",",as.character(coordA$lonR[2])," ",as.character(coordA$latR[1]),",",as.character(coordA$lonR[2])," ",as.character(coordA$latR[2]),",",as.character(coordA$lonR[1])," ",as.character(coordA$latR[2]),",",as.character(coordA$lonR[1])," ",as.character(coordA$latR[1]),"))",sep=""))
  polygonB <- readWKT(paste("POLYGON((",as.character(coordB$lonR[1])," ",as.character(coordB$latR[1]),",",as.character(coordB$lonR[2])," ",as.character(coordB$latR[1]),",",as.character(coordB$lonR[2])," ",as.character(coordB$latR[2]),",",as.character(coordB$lonR[1])," ",as.character(coordB$latR[2]),",",as.character(coordB$lonR[1])," ",as.character(coordB$latR[1]),"))",sep=""))

  intersectionAB <- gIntersection(polygonA,polygonB)
  if(is.null(intersectionAB)) return(0)

  areaA <- gArea(polygonA)
  areaAB <- gArea(intersectionAB)

  return(areaAB/areaA)
}

#' Get Basemap
#'
#' @param source Google Maps ("google"), OpenStreetMap ("osm") or Stamen Maps ("stamen")
#' @param maptype Character string providing map theme, which depends on the source
#' @param bbox Bounding box of the layer (spCoverage)
#' @param zoom Map zoom (leave it NULL for auto zoom)
#'
#' @return A map to be used by ggmap function
getBaseMap <- function(source, maptype, bbox, zoom=NULL)
{
  if(is.null(zoom)) zoom <- calc_zoom(bbox)
  bbox10p <- make_bbox(bbox[c(1,3)],bbox[c(2,4)],f=0.1)
  if(source == "google") myMap <- get_googlemap(center=getCentre(bbox), zoom=zoom-1, maptype=maptype)
  else if(source == "stamen") myMap <- get_stamenmap(bbox10p, zoom=zoom, maptype=maptype, crop=TRUE)
  else if(source == "osm") myMap <- get_map(bbox10p, zoom=zoom, source="osm")
  return(myMap)
}

#' Get Centre
#'
#' This function receives a bounding box and returns the coordinates of its centre
#'
#' @param bbox Bouding box
#'
#' @return vector with lon and lat of the centre
getCentre <- function(bbox)
{
  c(lon=mean(bbox[c(1,3)]),lat=mean(bbox[c(2,4)]))
}


#' Bbox to polygon
#'
#' This function receives a bounding box and returns a dataframe with the coordinates to make a polygon plot
#'
#' @param bbox Bouding box
#'
#' @return dataframe with 4 points
bboxToPolygon <- function(bbox)
{
  x <- bbox[c(1,1,3,3)]
  y <- bbox[c(2,4,4,2)]
  df <- data.frame(x, y)
  return(df)
}

#' Get Extremes
#'
#' \code{getExtremes} returns a vector with the maximum and the minimum element of the input vector.
#'
#' @param v Input vector.
#'
#' @return A 2-element vector (min, max).
#'
#' @examples
#' x <- (1,2,3,4,5)
#' getExtremes(x)
getExtremes <- function(v)
{
  return(c(min(v,na.rm=TRUE), max(v,na.rm=TRUE)))
}


#' New Timestamp
#'
#' \code{newTimestamp} creates a timestamp object according to the input
#'
#' @param year Year
#' @param mon Month
#' @param mday Day of the month
#' @param hour Hour
#' @param min Minutes
#' @param sec Seconds
#' @param wday Day of the week
#' @param yday Day of the year
#' @param tz Time zone
#'
#' @return a POSIXlt object
newTimestamp <- function(year="1900",mon="01",mday="01",hour="00",min="00",sec="00", wday=NULL, yday=NULL, tz="UTC")
{
  if(is.null(year)) year <- "1900"
  if(is.null(mon)) mon <- "01"
  if(is.null(mday)) mday <- "01"
  if(is.null(hour)) hour <- "00"
  if(is.null(min)) min <- "00"
  if(is.null(sec)) sec <- "00"

  timestamp <- as.POSIXlt(paste(paste(year,mon,mday,sep="-"),paste(hour,min,sec,sep=":"),sep=" "),tz=tz)

  if(!is.null(wday))
  {
    wday.current <- timestamp$wday
    wday.real <- wday
    mday.current <- timestamp$mday
    mday.real <- mday.current + (wday.real - wday.current)%%7

    timestamp$mday <- mday.real
    # since $wday goes from 0-6 instead of 1-7
    timestamp$wday <- wday.real-1
  }
  if(!is.null(yday))
  {
    # since $yday goes from 0-364
    timestamp$yday <- yday-1
  }

  return(timestamp)
}
