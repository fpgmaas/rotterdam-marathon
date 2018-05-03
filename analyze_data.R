### TODO parse chron to numeric in read_data()
library(XML)
library(data.table)
library(plotly)

df_runners = readRDS('data/result.RDS')

doc = xmlParse("data/Marathon Rotterdam 2018.tcx")
nodes <- getNodeSet(doc, "//ns:Trackpoint", "ns")
df_track  <- plyr::ldply(nodes, as.data.frame(xmlToList))
df_track  <- setNames(df_track, c('time', 'lat', 'lon', 'alt', 'distance'))
df_track$time <- NULL
for (column in colnames(df_track))
{
  df_track[[column]] <- as.numeric(as.character(df_track[[column]]))
}
tot_dist = max(df_track$distance)
rm(column,doc,nodes)

df_runners$lat_noise = runif(nrow(df_runners),-0.0009,0.0009)
df_runners$lon_noise = runif(nrow(df_runners),-0.0009,0.0009)

for(minute in 100:110)
{
  lon_list = vector('numeric',nrow(df_runners))
  lat_list = vector('numeric',nrow(df_runners))
  
  for(runner in 1:nrow(df_runners))
  {
    m_passed = tot_dist / (as.numeric(df_runners[runner,primaryDisplayTime])*60*24) * minute
    point_1 = max(which(m_passed>df_track$distance))
    point_2 = point_1 + 1
    lon_list[runner] = (df_track$lon[point_1] + df_track$lon[point_2])/2 + df_runners[runner,lon_noise]
    lat_list[runner] = (df_track$lat[point_1] + df_track$lat[point_2])/2 + df_runners[runner,lat_noise]
  }
  position_df = data.frame(lon=lon_list,lat=lat_list)
  
  
  library(ggmap)
  #rdam_map <- get_map(location = c(4.48,51.90), maptype = "terrain", source = "google", zoom = 12)
  #> Map from URL : http://maps.googleapis.com/maps/api/staticmap?center=36.971709,-122.080954&zoom=14&size=640x640&scale=2&maptype=terrain&language=en-EN&sensor=false
  png(paste0('images/',minute,'.png'),800,800)
  print(ggmap(rdam_map) +
    geom_path(data = df_track, aes(color = alt), size = 3, lineend = "round") + 
    scale_color_gradientn(colours = rainbow(7), breaks = seq(25, 200, by = 25)) +
    geom_point(data=position_df,aes(x=lon,y=lat),size=0.01))
  dev.off()
}
