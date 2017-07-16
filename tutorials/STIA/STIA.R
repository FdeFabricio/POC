# load the main file
source("../../slkit.R")

# load the data frames
ig <- read.table("../data/instagram.dat", header=TRUE, stringsAsFactors=FALSE)
ci <- read.table("../data/checkin.dat", header=TRUE, stringsAsFactors=FALSE)
wu <- read.csv("../data/weatherunderground.csv", header=TRUE, stringsAsFactors=FALSE)
nt <- read.csv("../data/noisetube.csv", header=TRUE, stringsAsFactors=FALSE)

# convert the datetime column into the correct type
ig$timestamp <- as.POSIXct(ig$timestamp, format="%Y-%m-%dT%H:%M:%SZ")
ci$timestamp <- as.POSIXct(ci$timestamp, format="%Y-%m-%dT%H:%M:%SZ")
wu$EST <- as.POSIXct(wu$EST, format="%d/%m/%Y", "UTC")
nt$timestamp <- as.POSIXct(nt$timestamp, format="%Y-%m-%dT%H:%M:%SZ")

# STIA
# Generate the intersection matrix (temporal and spatial).
# wu is not included in the spatial one since the df does not have coordinates
tempList <- list(checkin=ci$timestamp, instagram=ig$timestamp, weatherUn=wu$EST, noiseTube=nt$timestamp)
spatList <- list(checkin=list(lat=ci$lat,lon=ci$lon),instagram=list(lat=ig$lat,lon=ig$lon), noiseTube=list(lat=nt$lat, lon=nt$lon))
STIA(T=tempList, S=spatList)
