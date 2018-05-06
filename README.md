Overview
--------

![](data/marathon2018_banner.jpg)

I recently came across a Twitter post by Alex Kruse who created a [time-lapse for the Hamburg marathon](https://twitter.com/krusealex2013/status/991604058396950528). I thought this was a really awesome idea and since I enjoy both running and R, I decided to try to do the same for the Rotterdam marathon 2018. This repository contains the R code that I used to create that time-lapse of the Rotterdam Marathon.

Result
------------

The result can be found [here on Youtube](https://www.youtube.com/watch?v=T67sLtW5Iic).

How does it work?
--------

This time-lapse is created by first downloading the results of all runners through the API of the [Mylaps Sporthive website](https://results.sporthive.com/events/6386505967023513344/races/419161), and secondly a tcx file containg the course layout that I found on [Strava](https://www.strava.com/clubs/175948/group_events/294139). The tcx file contains a track that is 42,679 meters long, which is slightly longer than the actual marathon.

The data contains split times at 5, 10, 15, 20, 21.2, 25, 30, 35, 40 kilometers and the finish time. At every minute we check for every runner in which interval he is currently running, and based on this we linearly interpolate his cumulative distance covered. Subsequently, we find from the tcx file the two points between which the runner is currently running, and interpolate his latitude and longitude from there.



Requirements
-----

I don't think anyone ever plans on running the entirety of this code again, but if that is the case, some requirements are:

- Patience. I only planned to run this code once so I did not do much to optimize the runtime, the large for-loop probably could benefit from the use of matrix-operations and/or vectorization.
- [ggmapstyles](https://github.com/mikey-harper/ggmapstyles) and a Google Maps API key stored in the file *key.json* to download the map of Rotterdam. I already saved the result to an RDS in the data folder so not really necessary. Note that *ggmapstyles* also requires the development version of *ggmap*.
- [ImageMagick](https://www.imagemagick.org/script/index.php) for the conversion of many *png*'s to *mkv*.



