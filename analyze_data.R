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

for (minute in 1:10)
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
  print(ggmap(rdam_map,extent = "panel") +
          geom_path(data = df_track, color='white',alpha=0.9, size = 3, lineend = "round") + 
          geom_point(data=df_position,aes(x=lon,y=lat),size=1.5,color='#EE7600',alpha=0.7) +
          theme_void() +
          theme(plot.title = element_text(hjust = 0.5,
                                          face = "bold", 
                                          size = (30),
                                          margin = margin(t = 20, r = 0, b = 10, l = 0)),
                plot.subtitle = element_text(hjust = 0.5,
                                             size = (22),
                                          margin = margin(t = 10, r = 0, b = 25, l = 0))
                ) +
          labs(title='Rotterdam Marathon 2018',subtitle='A timelapse of all runners') +
          annotate("text", x = 4.45, y = 51.95, label = sprintf('%02d:%02d', td@hour, minute(td)),color='white',size=13) +
          scale_x_continuous(limits = c(4.466-0.03, 4.546+0.03), expand = c(0, 0)) +
          scale_y_continuous(limits = c(51.87-0.01, 51.95+0.01), expand = c(0, 0))
  )
  dev.off()
}

