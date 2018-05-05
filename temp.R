make.mov <- function(){
  unlink("plot.mpg")
  system("magick -delay 0.5 *.png plot.mpg")
}

system('"C:\\Program Files (x86)\\LyX 2.0\\imagemagick\\convert.exe" -delay 20 -loop 0 files_*.png animation.gif')
convert -delay 6 -quality 95 test*ppm movie.mpg

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

system('ffmpeg -framerate 4 -i images/test/%04d.png -codec copy images/test/output.mkv')
