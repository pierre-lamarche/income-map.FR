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
url_map = "https://wxs-telechargement.ign.fr/oikr5jryiph0iwhw36053ptm/telechargement/inspire/GEOFLA_THEME-COMMUNE_2016$GEOFLA_2-2_COMMUNE_SHP_LAMB93_FXX_2016-06-28/file/GEOFLA_2-2_COMMUNE_SHP_LAMB93_FXX_2016-06-28.7z"
url_filosofi = "http://www.insee.fr/fr/ppp/bases-de-donnees/donnees-detaillees/filosofi/filosofi-2012/indic-struct-distrib-revenu/indic-struct-distrib-revenu-communes-2012.zip"

folder = tk_choose.dir(default=getwd(),"Choose the folder where to store the data:")

dir.create(paste0(folder,"/map"))
download.file(url=url_map,destfile = paste0(folder,"/map/archive.7z"),mode="wb")
unz(paste0(folder,"/map/archive.7z"),"COMMUNE.SHP",open="r")

dir.create(paste0(folder,"/data"))
download.file(url=url_filosofi,destfile = paste0(folder,"/data/archive.zip"),mode="wb")
unzip(zipfile=paste0(folder,"/data/archive.zip"),exdir=paste0(folder,"/data"))



#### load map

setwd(paste0(folder,"/map"))
commune=readShapeSpatial("COMMUNE",proj4string=CRS("+init=epsg:2154"))
commune_data = commune@data

#### load data

setwd(paste0(folder,"/data"))
#options(java.parameters = "-Xmx1000m")
gc()
commune_revenu = readWorksheetFromFile("FILO_DISP_COM.xls",sheet="ENSEMBLE",header=TRUE,
                                       startRow=6,endRow=32956)



#### Tcl/Tk interface ------

opening_windows = function(){
  
}

