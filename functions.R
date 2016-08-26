require(sqldf)
require(RColorBrewer)

#### function to generate the data for the map

map_france_income = function(map=,data=,type_zone="ALL",zone=NULL,indicator=,file_output=) {
  tab_revenu = sqldf(paste0("select CODGEO, LIBGEO, NBMEN12, ",indicator,"from ",data,
                            " where CODGEO in (select INSEE_COM from commune_data) and 
                            ",type_zone,"='",zone,"'")
  
  commune_tot = merge(map,tab_revenu,by.x="INSEE_COM",by.y="CODGEO",all = FALSE,all.y = TRUE)
  return(commune_tot)
}


#### function to select the number of categories

select_legend = function(x=,cutoff_points=) {
  
  nclasses = length(cutoff_points)
  colors = c(brewer.pal(ceiling(nclasses/2),"OrRd"),brewer.pal(ceiling(nclasses/2),"GnBu"))
  classes = classIntervals(x,nclasses,style="fixed",fixedBreaks=cutoff_points)
  colCode = findColours(classes,colors)
}