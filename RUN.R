packages.available = installed.packages()
if (!"tcltk" %in% row.names(packages.available)) install.packages("tcltk")
if (!"tcltk2" %in% row.names(packages.available)) install.packages("tcltk2")
if (!"maptools" %in% row.names(packages.available)) install.packages("maptools")
if (!"rgdal" %in% row.names(packages.available)) install.packages("rgdal")
if (!"XLConnect" %in% row.names(packages.available)) install.packages("XLConnect")
if (!"sqldf" %in% row.names(packages.available)) install.packages("sqldf")
if (!"RColorBrewer" %in% row.names(packages.available)) install.packages("RColorBrewer")
if (!"classInt" %in% row.names(packages.available)) install.packages("classInt")

library(tcltk)
library(tcltk2)
library(maptools)
library(rgdal)
gpclibPermit()
library(XLConnect)
library(sqldf)
library(classInt)




downloadFilo <- function() {
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
    download.file(url = paste0(url_map,"/",list_shp[k]),destfile = paste0(folder,"/map/",list_shp[k]),mode="wb")
  }
  ### unz(paste0(folder,"/map/archive.7z"),"COMMUNE.SHP",open="r")
  
  dir.create(paste0(folder,"/data"))
  download.file(url = url_filosofi,destfile = paste0(folder,"/data/archive.zip"),mode = "wb")
  unzip(zipfile = paste0(folder,"/data/archive.zip"), exdir = paste0(folder,"/data"))
  
  #### load map
  
  setwd(paste0(folder,"/map"))
  commune <- readShapeSpatial("COMMUNE",proj4string = CRS("+init=epsg:2154"))
  commune_data <- commune@data
  
  #### load data
  
  setwd(paste0(folder,"/data"))
  gc()
  commune_revenu <- readWorksheetFromFile("FILO_DISP_COM.xls",sheet = "ENSEMBLE",header = TRUE,
                                          startRow = 6,endRow = 32956)
  
  #### assign data in the Global environment
  assign("folder", folder, env = .GlobalEnv)
  assign("commune", commune, env = .GlobalEnv)
  assign("commune_data", commune_data, env = .GlobalEnv)
  assign("commune_revenu", commune_revenu, env = .GlobalEnv)
}




########################################################################################
#### Tcl/Tk interface ------
########################################################################################

openWinStart <- function() {
  # function to start the app
  # start window
  winStart <- tktoplevel()
  tktitle(winStart) <- "income-map.FR"
  # 2 choices: either data at the municipality level, or squared data
  winStart$env$butFilo <- ttkbutton(winStart, text = "Municipality level (FILOSOFI data)", 
                                    width = -6, command = function() {
                                      tkdestroy(winStart)
                                      openWinFilo()}
                                      )
#  winStart$env$butCarr <- ttkbutton(winStart, text = "Squarred data (1km2 or 200m2)", 
#                                    width = -6, command = tkdestroy(winStart))
  tkgrid(winStart$env$butFilo, padx = 70, pady = 30)
#  tkgrid(winStart$env$butCarr, padx = 70, pady = 30)
}

openWinFilo <- function() {
  # function to start Filosofi part
  # first download the data
  #downloadFilo()
  # open the window
  winFilo <- tktoplevel()
  tktitle(winFilo) <- "income-map.FR - FILOSOFI"
  # 3 choices (button radio) - France, NUTS2, NUTS3
  winFilo$env$rb1 <- tk2radiobutton(winFilo)
  winFilo$env$rb2 <- tk2radiobutton(winFilo)
  winFilo$env$rb3 <- tk2radiobutton(winFilo)
  typeZone <- tclVar("ALL")
  tkconfigure(winFilo$env$rb1, variable = typeZone, value = "ALL")
  tkconfigure(winFilo$env$rb2, variable = typeZone, value = "REG")
  tkconfigure(winFilo$env$rb3, variable = typeZone, value = "DEPT")
  # display the radio buttons
  tkgrid(tk2label(winFilo, text = "Choose the geographical level for the map:"),
         columnspan = 2, padx = 10, pady = c(15, 5))
  tkgrid(tk2label(winFilo, text = "France"), winFilo$env$rb1,
         padx = 10, pady = c(0, 5))
  tkgrid(tk2label(winFilo, text = "Regional level (NUTS 2)"), winFilo$env$rb2,
         padx = 10, pady = c(0, 5))
  tkgrid(tk2label(winFilo, text = "Departement level (NUTS 3)"), winFilo$env$rb3,
         padx = 10, pady = c(0, 5))
  # display the ok button
  winFilo$env$butOK <- tk2button(winFilo, text = "OK", width = -6, command = function() {
    tkdestroy(winFilo)
    winFiloOnOk(tclvalue(typeZone))}
    )
  tkgrid(winFilo$env$butOK, columnspan = 2, padx = 10, pady = c(5, 15))
  tkfocus(winFilo)
}

winFiloOnOk <- function(tZ) {
  # function for the OK button on window Filosofi
  if (tZ == "ALL") {
    generateMapFR()
  } else {
    if (tZ == "REG") {
      title <- "region (NUTS-2)"
    } else title <- "departement (NUTS-3)"
    winSelectZone(tZ, title)
  }
}

winSelectZone <- function(typeZone, title) {
  # function opening a window to select the zone
  # Parms: 
  # - typeZone: type of zone to select (NUTS2 or NUTS3) - "REG" or "DEPT"
  # - title: title for the window
  
  winSelect <- tktoplevel()
  tktitle(winSelect) <- paste0("Select the ",title)
  winSelect$env$lst <- tk2listbox(winSelect, height = 10, selectmode = "single")
  tkgrid(tk2label(winSelect, text = paste0("Select the ", title, " which you want to map"), justify = "left"),
         padx = 20, pady =c(15, 5), sticky = "w")
  tkgrid(winSelect$env$lst, padx = 10, pady = c(5, 10))
  
  listZone <- generateListZone(typeZone)
  listChoice <- paste0(listZone$CODE_ZONE[,1]," - ",listZone$NOM_ZONE[,1])
  for (z in listChoice)
    tkinsert(winSelect$env$lst, "end", z)
  tkselection.set(winSelect$env$lst, 0)

  winSelect$env$butOK <-tk2button(winSelect, text = "OK", width = -6, command = function() {
    choosedZone <- listZone$CODE_ZONE[as.numeric(tkcurselection(winSelect$env$lst)) + 1,1]
    tkdestroy(winSelect)
    generateMapFR(typeZone,choosedZone)
  })
  tkgrid(winSelect$env$butOK, padx = 10, pady = c(5, 15))
  
}

openWinStart()
