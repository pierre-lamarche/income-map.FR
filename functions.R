require(sqldf)
require(RColorBrewer)


mapFranceIncome <- function(map, data, type_zone = "ALL", indicator = "Q212", zone = NULL) {
  # function to generate the data for the map
  # Parms:
  # - map: name of the SpatialPolygonDataFrame object
  # - data: name of the data frame to be merged with the map object
  # - type_zone (opt.): level of geographical level on which you want to work.
  # Only three types are possible: "ALL" - the default - selects the entire territory
  #                                "DEPT" selects data at NUTS-3 level
  #                                "REG" select data at NUTS-2 level
  # - indicator: name of the variable to be displayed in the map - default is the median (Q212)
  # - zone: if type_zone is not equal to "ALL", then zone should be filed with the relevant
  # code (NUTS-2 or NUTS-3)
  #
  # Returns: a SpatialPolygonDataFrame enriched with data contained in `data` and subset to the
  # relevant geographical area

  # critical checks
  if (is.na(map)) stop("Parameter map is missing.")
  if (is.na(data)) stop("Parameter data is missing.")
  if (!exists(as.character(parse(text = map)))) stop(paste0("Object ",map," cannot be found."))
  if (!exists(as.character(parse(text = data)))) stop(paste0("Object ",data," cannot be found."))
  # store data
  MAP <- eval(parse(text = map))
  DATA <- eval(parse(text = data))
  # check parameter type_zone
  if (!type_zone %in% c("ALL","DEPT","REG")) stop("Unknown geographical level.")
  # check parameters type_zone + zone
  if (type_zone %in% c("DEPT","REG") & is.null(zone)) stop("Geographical level not defined.")
  if (type_zone == "DEPT") {
    list_dpt <- unique(MAP@data$CODE_DEPT)
    if (!zone %in% list_dpt) stop("Unknown departement code.")
  }
  if (type_zone == "REG") {
    list_reg <- unique(MAP@data$CODE_REG)
    if (!zone %in% list_reg) stop("Unknown region code.")
  }
  
  # rename properly the columns for NUTS2/NUTS3
  if (type_zone == "DEPT") type_zone <- "CODE_DEPT"
  if (type_zone == "REG") type_zone <- "CODE_REG"
  # build SQL request out of the parameters
  communeData <- MAP@data
  if (type_zone != "ALL") {
    sql_req <- paste0("select * from communeData where ",type_zone," = '",zone,"'")
    communeData <- sqldf(sql_req)
  }
  sql_req <- paste0("select CODGEO, LIBGEO, NBMEN12, ",indicator,
                    " from DATA where CODGEO in (select INSEE_COM from communeData)")
  # extract data from `data` on the relevant area
  tab_revenu <- sqldf(sql_req)
  # merge with map information, get a SpatialPolygonDataFrame
  comToMerge <- data.frame(INSEE_COM = communeData[,"INSEE_COM"])
  MAP <- merge(MAP, comToMerge, by = "INSEE_COM", all = FALSE, all.y = TRUE)
  commune_tot <- merge(MAP, tab_revenu, by.x = "INSEE_COM", by.y = "CODGEO", all = TRUE)
  return(commune_tot)
}

generateListZone <- function(typeZone) {
  # function that will select in the database `commune_data` the list of possible zones
  # for a given type of zone
  # Parms:
  # - typeZone: designates the type of zone - "REG" (NUTS2) or "DEPT" (NUTS3)
  #
  # Returns: an object containing the list of possible zones and their names
  
  listZ <- sqldf(paste0("select distinct CODE_", typeZone, " from commune_data 
                        order by CODE_", typeZone))
  listN <- sqldf(paste0("select distinct NOM_", typeZone, " from commune_data 
                        order by CODE_", typeZone))
  return(list(CODE_ZONE = listZ, NOM_ZONE = listN))
}

generateMapFR <- function(typeZone = "ALL", zone = NULL) {
  # function generating the png file with the requested map
  # Parms:
  # - typeZone: same parameter as type_zone in `mapFranceIncome`
  # - zone: idem
  # 
  # Returns: nothing - but generate a variable `tempFile` containing the name of the 
  # pnf file.
  
  mapData <- mapFranceIncome(map = "commune", data = "commune_revenu", type_zone = typeZone
                             ,zone = zone)
  # name of the temporary file
  tempFile <- tempfile(fileext = ".png")
  assign("tempFile", tempFile, env = .GlobalEnv)
  # create the vector of colors
  colCode <- selectLegend(x = mapData@data$Q212, cutoff_points = c(0,10000,15000,20000,30000,50000))

  png(filename = tempFile, width = 900, height = 900, units = 'px')
  plot(mapData,col=colCode,border = FALSE)
  legend("topleft", legend=c("Moins de 10 000 euros","10 à 15 000 euros","15 à 20 000 euros",
                             "20 à 30 000 euros","35 000 euros et plus","Données anonymisées"),
         col=c(attr(colCode,"palette"),"lightgrey"),pch=15, cex = 0.8)
  dev.off()
  
  winDisplayMap(tempFile)
}

winDisplayMap <- function(path) {
  # create image out of the pgn file
  tcl("image","create","photo", "imageMap", file=path)
  
  winDisMap <- tktoplevel()
  winDisMap$env$menu <- tk2menu(winDisMap)
  # configure menu
  tkconfigure(winDisMap, menu = winDisMap$env$menu)
  # menu "File"
  winDisMap$env$menuFile <- tk2menu(winDisMap$env$menu, tearoff = FALSE)
  # option Save the map
  tkadd(winDisMap$env$menuFile, "command", label = "Save map", 
        command = function() saveMap(path))
  # option Reinitilise
  tkadd(winDisMap$env$menuFile, "command", label = "Reinitialise map",
        command = function() {
          tkdestroy(winDisMap)
          openWinStart()
        })
  # option Quit
  tkadd(winDisMap$env$menuFile, "command", label = "Quit", 
        command = function() tkdestroy(winDisMap))
  
  tkadd(winDisMap$env$menu, "cascade", label = "File", menu = winDisMap$env$menuFile)
  
  # display the map
  tkpack(ttklabel(winDisMap, image="imageMap", compound="image"))
}

saveMap <- function(file) {
  mapPath <- tclvalue(tkgetSaveFile(initialdir = getwd(), #intialfile = , 
                                    filetypes = "{{PNG files} {.png}}",
                                    defaultextension = ".png"))
  file.copy(file, mapPath)
  file.remove(file)
}


#### function to select the number of categories

selectLegend <- function(x, cutoff_points) {
  
  nclasses <- length(cutoff_points)
  colors <- c(brewer.pal(ceiling(nclasses/2),"OrRd"),brewer.pal(ceiling(nclasses/2),"GnBu"))
  classes <- classIntervals(x,nclasses,style="fixed",fixedBreaks=cutoff_points)
  colCode <- findColours(classes,colors)
  
  colCode[is.na(colCode)] <- "lightgrey"
  return(colCode)
}