require(sqldf)
require(RColorBrewer)


map_france_income <- function(map,data,type_zone="ALL",indicator="Q212",zone=NULL) {
  # map_france_income function
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
  if (!exists(as.character(parse(text=map)))) stop(paste0("Object ",map," cannot be found."))
  if (!exists(as.character(parse(text=data)))) stop(paste0("Object ",data," cannot be found."))
  # store data
  MAP <- eval(parse(text=map))
  DATA <- eval(parse(text=data))
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
  commune_data <- MAP@data
  sql_req <- paste0("select CODGEO, LIBGEO, NBMEN12, ",indicator,
                    " from DATA where CODGEO in (select INSEE_COM from commune_data")
  if (type_zone != "ALL") sql_req <- paste0(sql_req," where ",type_zone," = '",zone,"'")
  sql_req <- paste0(sql_req,")")
  # extract data from `data` on the relevant area
  tab_revenu <- sqldf(sql_req)
  # merge with map information, get a SpatialPolygonDataFrame
  commune_tot <- merge(MAP,tab_revenu,by.x="INSEE_COM",by.y="CODGEO",all = FALSE,all.y = TRUE)
  return(commune_tot)
}


#### function to select the number of categories

select_legend <- function(x,cutoff_points) {
  
  nclasses <- length(cutoff_points)
  colors <- c(brewer.pal(ceiling(nclasses/2),"OrRd"),brewer.pal(ceiling(nclasses/2),"GnBu"))
  classes <- classIntervals(x,nclasses,style="fixed",fixedBreaks=cutoff_points)
  colCode <- findColours(classes,colors)
  
  colCode[is.na(colCode)] <- "lightgrey"
}