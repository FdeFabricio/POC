# load the main file
source("../../POC.R")

# load the data frames
ig <- read.table("../src/instagram.dat", header=FALSE, stringsAsFactors=FALSE)
ci <- read.table("../src/checkin.dat", header=FALSE, stringsAsFactors=FALSE)
wu <- read.csv("../src/weatherunderground.csv", header=TRUE, stringsAsFactors=FALSE)
nt <- read.csv("../src/noisetube.csv", header=TRUE, stringsAsFactors=FALSE)

# convert the datetime column into the correct class
ig$V2 <- as.POSIXct(ig$V2, format="%Y-%m-%dT%H:%M:%SZ")
ci$V2 <- as.POSIXct(ci$V2, format="%Y-%m-%dT%H:%M:%SZ")
wu$EST <- as.POSIXct(wu$EST, format="%Y-%m-%d", "UTC")
nt$made_at <- as.POSIXct(nt$made_at, format="%Y-%m-%dT%H:%M:%SZ")

# STIA
# Generate the intersection matrix (temporal and spatial).
# wu is not included in the spatial one since the df does not have coordinates
tempList <- list(checkin=ci$V2, instagram=ig$V2, weatherUn=wu$EST, noiseTube=nt$made_at)
spatList <- list(checkin=list(lat=ci$V3,lon=ci$V4),instagram=list(lat=ig$V3,lon=ig$V4), noiseTube=list(lat=nt$lat, lon=nt$lng))
STIA(T=tempList, S=spatList)
