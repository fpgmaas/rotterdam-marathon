library(ggmap)
library(ggmapstyles)
library(data.table)
library(rjson)

# Read the map
get_map <- function()
{
  if(file.exists('data/rdam_map.RDS'))
  {
    rdam_map <- readRDS('data/rdam_map.RDS')
  }
  else
  {
  rdam_map <- get_snazzymap(center = c(4.48,51.90),
                            zoom = 12,
                            mapRef = "https://snazzymaps.com/style/72543/assassins-creed-iv")
  saveRDS(rdam_map,'data/rdam_map.RDS')
  }
  return(rdam_map)
}

register_google_from_json <- function()
{
  register_google(fromJSON(file='data/key.json')$key)
}

