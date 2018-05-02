library(data.table)
library(dplyr)
library(plotly)
library(rvest)

n=80
count=25
offset=0
k=1
result = vector('list',ceiling(n/count))


for(k in 1:ceiling(n/count))
{
  url <- paste0('https://eventresults-api.sporthive.com/api/events/6386505967023513344/races/419161/classifications/search?count=',
                min(count,n-(offset)),'&offset=',offset)
  print(url)
  offset=count+offset
  
  page <- read_html(url)
  json_data <- fromJSON(file=url)
  
  l = vector('list',150)
  
  for(i in 1:length(json_data[[3]]))
  {
    l[[i]] = c(list(
      json_data[[3]][[i]]$athlete$name,
      json_data[[3]][[i]]$classification$bib,
      json_data[[3]][[i]]$classification$category,
      json_data[[3]][[i]]$classification$genderRank,
      json_data[[3]][[i]]$classification$rank,
      json_data[[3]][[i]]$classification$categoryRank,
      json_data[[3]][[i]]$classification$primaryDisplayTime,
      json_data[[3]][[i]]$classification$name,
      json_data[[3]][[i]]$classification$countryCode,
      json_data[[3]][[i]]$classification$gender,
      json_data[[3]][[i]]$classification$city),
      
      sapply(1:10,function(x){c(
        list(json_data[[3]][[i]]$classification$splits[[x]]$name,
             json_data[[3]][[i]]$classification$splits[[x]]$cumulativeTime))
      })
    )
    l[[i]] = lapply(l[[i]], function(x) ifelse(is.null(x), NA, x))
  }
  result[[k]] = rbindlist(l)
  
}


