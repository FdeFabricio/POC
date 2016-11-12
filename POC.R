library(ggmap)
library(rgeos)
library(raster)

getExtremes <- function(list)
{
  x <- c(min(list), max(list))
  return(x)
}

#' Spatial Coverage.
#' 
#' \code(spCoverage) returns the spatial coverage of a given dataframe.
#' 
#' This property represents the area the data is inserted into. It receives the 
#' longitude and latitude columns and returns the extreme coordinates (maximum 
#' and minimum), forming a bounding box.
#' 
#' @param lon Longitude column.
#' @param lat Latitude column.
#' @return The output is a vector with max and min coordinates, as a bounding 
#'   box.
#'   
#'   If \code{plotBbox} is TRUE, it plots the bounding box with the colour 
#'   informed in \code{colourBbox}.
#'   
#'   If \code{plotData} is TRUE, it plots also the data as points with the 
#'   colour informed in \code{colourData}.
spCoverage <- function(lon, lat, plotBbox=FALSE, colourBbox="black", plotData=FALSE, colourData="yellow")
{
  coverage <- c(getExtremes(lon),getExtremes(lat))
  coverage <- c(left=coverage[1], bottom=coverage[3], right=coverage[2], top=coverage[4])
  if (plotBbox == FALSE)
  {
    return(coverage)
  }
  print(coverage)
  
  myMap <-get_map(location=coverage, source="stamen", maptype="watercolor", crop=FALSE)
  
  x <- c(coverage["left"], coverage["left"], coverage["right"], coverage["right"])
  y <- c(coverage["bottom"], coverage["top"], coverage["top"], coverage["bottom"])
  df <- data.frame(x, y)
  
  # Plotting
  dataPlot <- geom_blank()
  areaPlot <- geom_polygon(aes(x=x, y=y), data=df, colour=colourBbox, fill=colourBbox, alpha=.4, size=.3)
  if (plotData == TRUE)
  {
    dataPlot <- geom_point(aes(x=lon, y=lat),  data=data.frame(lon,lat), size=.3, colour=colourData)
  }
  ggmap(myMap)+areaPlot+dataPlot

}

spCoverageList <- function(list)
{
  coord <- list(lon=c(),lat=c()) 
  polygon <- list()
  names <- names(list)
  for (i in 1:length(list))
  {
    lon <- list[[i]][[1]]
    lat <- list[[i]][[2]]
    colour <- list[[i]][[3]]
    
    coverage <- spCoverage(lon, lat)
    
    coord$lon[length(coord$lon)+1] <- coverage$lonR[1]
    coord$lon[length(coord$lon)+1] <- coverage$lonR[2]
    coord$lat[length(coord$lat)+1] <- coverage$latR[1]
    coord$lat[length(coord$lat)+1] <- coverage$latR[2]
    
    x <- c(coverage$lonR[1], coverage$lonR[1], coverage$lonR[2], coverage$lonR[2])
    y <- c(coverage$latR[1], coverage$latR[2], coverage$latR[2], coverage$latR[1])
    df.coverage = data.frame(x, y)
    polygon[[names[i]]] <- geom_polygon(aes(x=x, y=y), data=data.frame(x, y), colour = colour, fill = colour, alpha = .4, size = .3)
    
  }
  myLocation <- c(min(coord$lon), min(coord$lat), max(coord$lon), max(coord$lat))
  myMap <-get_map(location=myLocation, source="stamen", maptype="watercolor", crop=FALSE)
  
  ggmap(myMap)+polygon
  
}

tpCoverage <- function(dataColumn, diff=FALSE)
{
  x <- getExtremes(dataColumn)
  if(diff) print(x[2]-x[1])
  return(x)
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

groupFrequency <- function(timestamp,value=NULL,by,fun=sum)
{
  sec <- as.POSIXlt(timestamp)$sec
  min <- as.POSIXlt(timestamp)$min
  hour <- as.POSIXlt(timestamp)$hour
  mday <- as.POSIXlt(timestamp)$mday
  mon <- as.POSIXlt(timestamp)$mon
  year <- as.POSIXlt(timestamp)$year
  wday <- as.POSIXlt(timestamp)$wday
  yday <- as.POSIXlt(timestamp)$yday

  mon <- mon+1
  year <- year+1900
  wday <- wday+1
  yday <- yday+1
  
  by2 <- list()
  for (i in 1:length(by))
  {
    by2[[by[[i]]]] <- eval(parse(text=by[[i]]))
  }
  
  if (is.null(value))
  {
    count <- 1
    df <- data.frame(year, mon, mday, hour, min, sec, wday, yday, count)
    return(aggregate(df$count, by=by2, FUN=fun))
  } else
  {
    df <- data.frame(year, mon, mday, hour, min, sec, wday, yday, value)
    return(aggregate(df$value, by=by2, FUN=fun))
  }
}

# nx - number of horizontal intervals the area is divided into
spDistribution <- function(x, y, nx, ny, plot=F, col="red")
{
  stopifnot(length(x) == length(y))
  
  minX <- min(x)
  minY <- min(y)
  maxX <- max(x)
  maxY <- max(y)
  
  m <- matrix(0,nrow=nx,ncol=ny)
  
  xStep <- (maxX-minX)/nx
  yStep <- (maxY-minY)/ny
  
  for (i in 1:length(x))
  {
    a <- floor(abs((x[i]-minX)/xStep))+1
    b <- floor(abs((y[i]-minY)/yStep))+1
    if((a<=nx)&&(b<=ny))
    {
      m[a,b] <- 1
    }
  }
  if (plot)
  {
    # raster plot
    r <- raster(xmn=minX, ymn=minY, xmx=maxX, ymx=maxY, nrows=nx, ncols=ny)
    r[] <- 0
    xy <- SpatialPoints(cbind(x,y))
    tab <- table(cellFromXY(r, xy))
    r[as.numeric(names(tab))] <- 1
    
    breakpoints <- c(0,0.5,1)
    colors <- c(adjustcolor("white",alpha.f=0),adjustcolor(col,alpha.f=0.7))
    rasterPlot <- as.raster(r,breaks=breakpoints,col=colors)
    
    # basemap
    map <- get_map(location=bbox(r), zoom=11)
    
    # bbox plot
    x <- c(bbox(r)[1],bbox(r)[1],bbox(r)[3],bbox(r)[3])
    y <- c(bbox(r)[2],bbox(r)[4],bbox(r)[4],bbox(r)[2])
    bboxPlot <- geom_polygon(aes(x=x, y=y), data=data.frame(x, y), colour = col, fill = NA)
    
    # generate plot
    ggmap(map)+inset_raster(rasterPlot,xmin=bbox(r)[1,1],ymin=bbox(r)[2,1],xmax=bbox(r)[1,2],ymax=bbox(r)[2,2])+bboxPlot
  }
  print(sum(m)/(nx*ny))
}

# Temporal Distribution
# This function calculates the percentage of the complete interval (temporal coverage)
# the data
# @column : timestamp column POSIXct/lt
# @res : resolution
tpDistribution <- function(column, res)
{
  cov <- tpCoverage(column)
  if(res == "yearly")
  {
    as.POSIXlt(paste(format(cov,"%Y"),"1-1",sep="-"))
    nTotal <- length(seq(from=cov[1],to=cov[2],by="1 year"))
    nData <- nrow(groupFrequency(column,by=c("year"))) 
  }
  else if(res == "monthly")
  {
    as.POSIXlt(paste(format(cov,"%Y-%m"),"1",sep="-"))
    nTotal <- length(seq(from=cov[1],to=cov[2],by="1 month"))
    nData <- nrow(groupFrequency(column,by=c("year","mon")))
  }
  else if (res == "daily")
  {
    as.POSIXlt(format(cov,"%Y-%m-%d"))
    nTotal <- length(seq(from=cov[1],to=cov[2],by="1 day"))
    nData <- nrow(groupFrequency(column,by=c("year","mon","mday")))
  }
  else if(res == "hourly")
  {
    as.POSIXlt(paste(format(cov,"%Y-%m-%d %H"),"00:00",sep=":"))
    nTotal <- length(seq(from=cov[1],to=cov[2],by="1 hour"))
    nData <- nrow(groupFrequency(column,by=c("year","mon","mday","hour"))) 
  }
  else if(res == "minutely")
  {
    as.POSIXlt(paste(format(cov,"%Y-%m-%d %H:%M"),"00",sep=":"))
    nTotal <- length(seq(from=cov[1],to=cov[2],by="1 min"))
    nData <- nrow(groupFrequency(column,by=c("year","mon","mday","hour","min"))) 
  }
  else if(res == "secondly")
  {
    # as.POSIXlt(paste(format(cov,"%Y-%m-%d %H:%M"),"00",sep=":"))
    nTotal <- length(seq(from=cov[1],to=cov[2],by="1 sec"))
    nData <- nrow(groupFrequency(column,by=c("year","mon","mday","hour","min","sec"))) 
  }
  return(nData/nTotal)
}

# getFormat <- function(string)
# {
#   if (string == "sec") return ("%S")
#   if (string == "min") return ("%M")
#   if (string == "hour") return ("%H")
#   if (string == "mday") return ("%d")
#   if (string == "mon") return ("%m")
#   if (string == "year") return ("%Y")
#   if (string == "wday") return ("%u")
#   if (string == "yday") return ("%j")
# }
