library(data.table)
library(rvest)
library(chron)

n=13997
count=25
offset=0
k=1
result = vector('list',ceiling(n/count))

nullToNa <- function(mylist)
{
  lapply(mylist, function(x) ifelse(is.null(x), NA, x))
}

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
   runner_data <- list(
      'name' = json_data[[3]][[i]]$athlete$name,
      'bib' = json_data[[3]][[i]]$classification$bib,
      'category' = json_data[[3]][[i]]$classification$category,
      'genderRank' = json_data[[3]][[i]]$classification$genderRank,
      'rank' = json_data[[3]][[i]]$classification$rank,
      'categoryRank' = json_data[[3]][[i]]$classification$categoryRank,
      'primaryDisplayTime' = json_data[[3]][[i]]$classification$primaryDisplayTime,
      'name' = json_data[[3]][[i]]$classification$name,
      'countryCode' = json_data[[3]][[i]]$classification$countryCode,
      'gender' = json_data[[3]][[i]]$classification$gender,
      'city' = json_data[[3]][[i]]$classification$city)
      
      split_data <- sapply(1:10,function(x){
        my_list <- nullToNa(list(json_data[[3]][[i]]$classification$splits[[x]]$name,
                          json_data[[3]][[i]]$classification$splits[[x]]$cumulativeTime))
        return(setNames(my_list,c(paste0('split',x), paste0('split',x,'_time'))))
      },simplify=F)
      
    l[[i]] = nullToNa(c(runner_data,unlist(split_data)))
  }
  result[[k]] = rbindlist(l)
}

result = rbindlist(result)
for(column in colnames(result)[grepl('time',colnames(result),ignore.case = T)])
{
 result[[column]] <- chron::times(result[[column]]) 
}

saveRDS(result,'data/result.RDS')
