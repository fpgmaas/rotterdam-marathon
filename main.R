# Set working directory
this.dir <- dirname(parent.frame(2)$ofile)
setwd(this.dir)

# Load libraries
library(ggmap)
library(ggmapstyles)
library(data.table)
library(rjson)
library(XML)
library(data.table)
library(lubridate)
library(chron)
source('funcs.R')

# Create the appropriate directories that are ignored in gitignore.
dir.create('images',showWarnings = F)
dir.create('images/magick',showWarnings = F)
dir.create('output',showWarnings = F)

# Read the base data; the results of the marathon, the track coordinates, and the map of Rotterdam.
df_runners = get_marathon_results()
df_track = get_track()
rdam_map <- get_map()
tot_dist = max(df_track$distance)

# Add some noise per runner, so they do not all run on the same straight line.
set.seed(1)
df_runners$lat_noise = runif(nrow(df_runners),-0.0008,0.0008)
df_runners$lon_noise = runif(nrow(df_runners),-0.0008,0.0008)

# Split times and dists
X <- get_split_times_per_runner_and_remove_incomplete_runners (df_runners)
df_runners <- X[['df_runners']]
split_times <- X[['split_times']]
split_dists <- get_split_dists(df_runners)

for (minute in seq(0,384,0.5))
{
  print(paste0('minute: ', minute))
  # Initialize lists to keep track of each runners' lat and lon.
  lon_list = vector('numeric',nrow(df_runners))
  lat_list = vector('numeric',nrow(df_runners))
  
  for(runner in 1:nrow(df_runners))
  {
    # Find for this runner in which interval he is running, i.e. between which split times.
    interval = findInterval(minute,split_times[[runner]])
    if(interval<11) # If the interval<11, he is still running.
    {
      # Find out how many meters this runner has covered by linearly interpolating, starting from his previously known split time.
      m_already_covered = split_dists[interval] 
      m_per_minute_this_interval =   diff(split_dists[c(interval,interval+1)]) / diff(split_times[[runner]][c(interval,interval+1)]) 
      minutes_spent_in_this_interval = minute-split_times[[runner]][interval]
      m_passed = m_already_covered + m_per_minute_this_interval*minutes_spent_in_this_interval
      
      # Find out between which two points the runner is running, and interpolate latitude and longitude.
      point_1 = findInterval(m_passed,df_track$distance)
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
  
  # Create data.frame with runners' positions and remove runners that are already finished
  df_position = data.frame(lon=lon_list,lat=lat_list)
  df_position = df_position[rowSums(is.na(df_position))==0,] 
  n_finished = nrow(df_runners)-nrow(df_position)
  
  png(paste0('images/',gsub('\\.','',formatC(minute, digits = 1, width=5, flag=0, format = "f")),'.png'),1080,1080)
  print(create_plot(df_position, df_track, minute, n_finished))
  dev.off()
}

# To create the clip from the images, move all files to images/magick with the appropriate naming format for the ffmpeg command.
k=1
files = list.files('images',include.dirs = F)
for(file in files)
{
  x = as.numeric(gsub('\\.png','',file))
  if(!is.na(x))
  {
    y = paste0('images/magick/',formatC(k, digits = 0, width=4, flag=0, format = "f"),'.png')
    file.copy(paste0('images/',file),y)
    k=k+1
  }
}

# Run system command to create MKV file.
system('ffmpeg -framerate 6 -y -i images/magick/%04d.png -codec copy output/timelapse.mkv')
