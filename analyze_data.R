### TODO parse chron to numeric in read_data()
library(XML)
library(data.table)
library(plotly)
library(ggmap)
library(ggmapstyles)
library(lubridate)

df_runners = readRDS('data/result.RDS')

# Read the track data
doc = xmlParse("data/Marathon Rotterdam 2018.tcx")
nodes <- getNodeSet(doc, "//ns:Trackpoint", "ns")
df_track  <- plyr::ldply(nodes, as.data.frame(xmlToList))
df_track  <- setNames(df_track, c('time', 'lat', 'lon', 'alt', 'distance'))
df_track$time <- NULL
for (column in colnames(df_track))
{
  df_track[[column]] <- as.numeric(as.character(df_track[[column]]))
}
df_track$lon[df_track$distance>39000] = df_track$lon[df_track$distance>39000] + 0.0015
df_track$lat[df_track$distance>39000] = df_track$lat[df_track$distance>39000] - 0.0009
tot_dist = max(df_track$distance)
rm(column,doc,nodes)

# Add some noise per runner, so they do not all run on the same straight line.
df_runners$lat_noise = runif(nrow(df_runners),-0.0006,0.0006)
df_runners$lon_noise = runif(nrow(df_runners),-0.0006,0.0006)

# Split times
split_cols = colnames(df_runners)[grepl('_time',colnames(df_runners))]
df_runners = df_runners[which(rowSums(is.na(df_runners[,split_cols,with=F]))<1),]
split_times = lapply(1:nrow(df_runners), function(x) {c(0,as.numeric(as.vector(df_runners[x,split_cols,with=F])))*60*24})
split_dists = as.character(as.vector(df_runners[1,colnames(df_runners)[grepl('split',colnames(df_runners))],with=F]))[c(T,F)]
split_dists = gsub('k','',split_dists)
split_dists = c(0,as.numeric(gsub('Finish','42.68',split_dists)))*1000

rdam_map = readRDS('data/rdam_map.RDS')

for (minute in 130:140)
{
  
  lon_list = vector('numeric',nrow(df_runners))
  lat_list = vector('numeric',nrow(df_runners))
  
  for(runner in 1:nrow(df_runners))
  {
    interval = findInterval(minute,split_times[[runner]])
    if(interval<11)
    {
      m_passed = split_dists[interval] + 
        diff(split_dists[c(interval,interval+1)]) / diff(split_times[[runner]][c(interval,interval+1)]) *
        (minute-split_times[[runner]][interval])
      
      point_1 = max(which(m_passed>df_track$distance))
      point_2 = point_1 + 1
      lon_list[runner] = (df_track$lon[point_1] + df_track$lon[point_2])/2 + df_runners[runner,lon_noise]
      lat_list[runner] = (df_track$lat[point_1] + df_track$lat[point_2])/2 + df_runners[runner,lat_noise]
    }
    else
    {
      lon_list[runner] = NA
      lat_list[runner] = NA
    }
  }
  
  df_position = data.frame(lon=lon_list,lat=lat_list)
  df_position = df_position[rowSums(is.na(df_position))==0,]
  
  td <- seconds_to_period(minute*60)
  # rdam_map <- get_map(location = c(4.48,51.90), maptype = "terrain", source = "google", zoom = 12)
  #> Map from URL : http://maps.googleapis.com/maps/api/staticmap?center=36.971709,-122.080954&zoom=14&size=640x640&scale=2&maptype=terrain&language=en-EN&sensor=false
  png(paste0('images/',minute,'.png'),800,800)
  print(ggmap(rdam_map) +
          geom_path(data = df_track, color='white',alpha=0.9, size = 3, lineend = "round") + 
          geom_point(data=df_position,aes(x=lon,y=lat),size=1,color='orange') +
          theme_void() +
          theme(plot.title = element_text(hjust = 0.5,
                                          family = "Helvetica", 
                                          face = "bold", 
                                          size = (30),
                                          margin = margin(t = 20, r = 0, b = 10, l = 0)),
                plot.subtitle = element_text(hjust = 0.5,
                                          family = "Helvetica",
                                          size = (22),
                                          margin = margin(t = 10, r = 0, b = 25, l = 0))
                ) +
          labs(title='Rotterdam Marathon 2018',subtitle='A timelapse of all runners') +
          annotate("text", x = 4.40, y = 51.96, label = sprintf('%02d:%02d', td@hour, minute(td)),color='white',size=11)
  )
  dev.off()
}

