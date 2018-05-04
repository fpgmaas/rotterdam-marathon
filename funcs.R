# Read the map
register_google(key='AIzaSyC3SYfoZfPeYBkX7ZwxcdZ2fLSWrFETEy4')

rdam_map <- get_snazzymap(center = c(4.48,51.90),
                          zoom = 12,
                          mapRef = "https://snazzymaps.com/style/72543/assassins-creed-iv")
saveRDS(rdam_map,'data/rdam_map.RDS')