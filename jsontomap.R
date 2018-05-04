library(rjson)
styles = fromJSON(file='data/assassins_creed.txt')
styles_list = list()
k=1
for(i in 1:length(styles))
{
  for(j in 1:length(styles[[i]]$stylers))
  {
    x<-c(styles[[i]]$featureType, 
        styles[[i]]$elementType,
        styles[[i]]$stylers[[j]]
      )
    x = setNames(x,c('feature','element',names(styles[[i]]$stylers[[j]])))
    if(k>1)
    {
    styles_list[[k]] = c('&style=',x)
    }
    else
    {
      styles_list[[k]] = x
    }
    k=k+1
  }
}


library(ggmap)
map <- get_googlemap(center = c(4.48,51.90),
                     zoom = 12,
                     style = unlist(styles_list))

ggmap(map)


devtools::install_github("mikey-harper/ggmapstyles")
library(ggmapstyles)
map <- get_snazzymap(center = c(4.48,51.90), 
                     zoom = 12,
                     mapRef = "https://snazzymaps.com/style/72543/assassins-creed-iv")
ggmap(map)
