Ferramenta para Extração de Propriedades e Análise de Múltiplas Camadas de Sensoriamento
====
## Property extraction

### Spatial Coverage

This property represents the area the data is inserted into. It receives the longitude and latitude columns and returns the extreme coordinates (maximum and minimum), forming a bounding box.

##### Parameters
- **lon:** longitude column
- **lat:** latitude column
- **plotBbox:** if TRUE, it plots the bounding box (default is FALSE)
- **colourBbox:** the colour of the bounding box (default is black)
- **plotData:** if TRUE, it also plots the data as points (default is FALSE)
- **colourData:** the colour of the points (default is yellow)

#### Example
Before anything we should source the file and one dataset.
```
source("POC.R")
ig <- read.table("data/instagram.dat", header=TRUE, stringsAsFactors=FALSE)
```

1. `spCoverage(ig$lon, ig$lat)` returns:
```
‏     left   bottom     right       top
-74.06077 40.63317 -73.76324  40.84902
```
2. `spCoverage(ig$lon, ig$lat, TRUE)` returns:

![](https://github.com/FdeFabricio/POC/blob/master/img/spCoverage1.jpg)

3. `spCoverage(ig$lon, ig$lat, plotBbox=TRUE, plotData=TRUE)` returns:
4. `spCoverage(ig$lon, ig$lat, TRUE, "red", TRUE, "white")` returns:

##### Analysis
1. [STIA](https://github.com/FdeFabricio/POC/tree/master/tutorials/STIA)
2. Correlation [in progress]
