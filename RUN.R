packages.available = installed.packages()
if (!"tcltk" %in% row.names(packages.available)) install.packages("tcltk")
if (!"maptools" %in% row.names(packages.available)) install.packages("maptools")
if (!"rgdal" %in% row.names(packages.available)) install.packages("rgdal")
if (!"XLConnect" %in% row.names(packages.available)) install.packages("XLConnect")
if (!"sqldf" %in% row.names(packages.available)) install.packages("sqldf")
if (!"RColorBrewer" %in% row.names(packages.available)) install.packages("RColorBrewer")

library(tcltk)
library(maptools)
library(rgdal)
gpclibPermit()
library(XLConnect)
library(sqldf)


#### dl the data
#### commenting the original url for downloading the shp files for the maps - issue when unzipping a .7z file with R
#### url_map <- "https://wxs-telechargement.ign.fr/oikr5jryiph0iwhw36053ptm/telechargement/inspire/GEOFLA_THEME-COMMUNE_2016$GEOFLA_2-2_COMMUNE_SHP_LAMB93_FXX_2016-06-28/file/GEOFLA_2-2_COMMUNE_SHP_LAMB93_FXX_2016-06-28.7z"
#### the workaround: the user directly downloads the data from a Github repo

url_map <- "https://github.com/pierre-lamarche/income-map.FR/raw/master/communes"
#### for the workaround it is necessary to add the list of files to be downloaded
list_shp <- c(paste("COMMUNE",c("DBF","LYR","PRJ","SHP","SHX"),sep="."),
              paste("LIMITE_COMMUNE",c("DBF","LYR","PRJ","SHP","SHX"),sep="."))
url_filosofi <- "http://www.insee.fr/fr/ppp/bases-de-donnees/donnees-detaillees/filosofi/filosofi-2012/indic-struct-distrib-revenu/indic-struct-distrib-revenu-communes-2012.zip"

folder = tk_choose.dir(default=getwd(),"Choose the folder where to store the data:")

dir.create(paste0(folder,"/map"))
for (k in 1:length(list_shp)) {
  download.file(url=paste0(url_map,"/",list_shp[k]),destfile = paste0(folder,"/map/",list_shp[k]),mode="wb")
}
### unz(paste0(folder,"/map/archive.7z"),"COMMUNE.SHP",open="r")

dir.create(paste0(folder,"/data"))
download.file(url=url_filosofi,destfile = paste0(folder,"/data/archive.zip"),mode="wb")
unzip(zipfile=paste0(folder,"/data/archive.zip"),exdir=paste0(folder,"/data"))



#### load map

setwd(paste0(folder,"/map"))
commune=readShapeSpatial("COMMUNE",proj4string=CRS("+init=epsg:2154"))
commune_data <- commune@data

#### load data

setwd(paste0(folder,"/data"))
#options(java.parameters = "-Xmx1000m")
gc()
commune_revenu <- readWorksheetFromFile("FILO_DISP_COM.xls",sheet="ENSEMBLE",header=TRUE,
                                       startRow=6,endRow=32956)



#### Tcl/Tk interface ------

opening_windows = function(){
  
}

