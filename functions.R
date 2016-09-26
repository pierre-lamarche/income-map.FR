require(sqldf)
require(RColorBrewer)

####################################################################################
#### map_france_income function
#### function to generate the data for the map
#### Parms:
#### - map: name of the SpatialPolygonDataFrame object
#### - data: name of the data frame to be merged with the map object
#### - type_zone (opt.): level of geographical level on which you want to work.
#### Only three types are possible: "ALL" - the default - selects the entire territory
####                                "DEPT" selects data at NUTS-2 level
####                                "REG" select data at NUTS-1 level
#### - indicator: 

map_france_income <- function(map,data,type_zone="ALL",indicator,file_output,
                              zone=NULL) {
  if (!type_zone %in% c("ALL","DEPT","REG")) stop("Unknown geographical level")
  if (type_zone %in% c("DEPT","REG") & is.null(zone)) stop("Geographical level not defined")
  if (type_zone == "DEPT") {
    list_dpt <- unique(map@data$CODE_DEPT)
    if (!zone %in% list_dpt) stop("Unknown departement code")
  }
  if (type_zone == "REG") {
    list_reg <- unique(map@data$CODE_REG)
    if (!zone %in% list_reg) stop("Unknown region code")
  }
  
  geo_lvl <- NA
  if (type_zone == "DEPT") geo_lvl <- 
  tab_revenu <- sqldf(paste0("select CODGEO, LIBGEO, NBMEN12, ",indicator,"from ",data,
                            " where CODGEO in (select INSEE_COM from commune_data) and 
                            ",type_zone,"='",zone,"'"))
  
  commune_tot <- merge(map,tab_revenu,by.x="INSEE_COM",by.y="CODGEO",all = FALSE,all.y = TRUE)
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