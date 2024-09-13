########################
### 01. study region ###
########################

# clear environment
rm(list = ls())

# calculate start time of code (determine how long it takes to complete all code)
start <- Sys.time()

#####################################
#####################################

# set parameters
## designate region name
region_name <- "ca"

## mariculture site
mariculture_site <- "sb"

## setback distance (1 nautical mile = 1852 meters)
setback <- 1852

## coordinate reference system
### set the coordinate reference system that data should become (NAD83 UTM 11N: https://epsg.io/26911)
crs <- "EPSG:26911"

## designate date
date <- format(Sys.Date(), "%Y%m%d")

#####################################
#####################################

# load packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(renv,
               dplyr,
               ggplot2,
               janitor,
               plyr,
               purrr,
               rmapshaper,
               sf,
               sp,
               stringr,
               targets,
               terra, # is replacing the raster package
               tidyr)

#####################################
#####################################

# Commentary on R and code formulation:
## ***Note: If not familiar with dplyr notation
## dplyr is within the tidyverse and can use %>%
## to "pipe" a process, allowing for fluidity
## Can learn more here: https://style.tidyverse.org/pipes.html

## another common coding notation used is "::"
## For instance, you may encounter it as dplyr::filter()
## This means "use the filter function from the dplyr package"
## Notation is used given sometimes different packages have
## the same function name, so it helps code to tell which
## package to use for that particular function.
## The notation is continued even when a function name is
## unique to a particular package so it is obvious which
## package is used

#####################################
#####################################

# set directories
## define data directory (as this is an R Project, pathnames are simplified)
### export geopackage
output_gpkg <- file.path("data/b_intermediate_data/", strinr::str_glue("{mariculture_site}_site.gpkg"))

#####################################
#####################################

# study Area
## create points for study area
### add points as they need to be drawn (clockwise or counterclockwise)
aoi_points <- rbind(c("point", -119.7022, 34.333233), # southeastern point
                    c("point", -119.7021, 34.336452), # northeastern point
                    c("point", -119.7127, 34.336145), # northwestern point
                    c("point", -119.7129, 34.332926)) %>% # southwestern point
  # convert to data frame
  as.data.frame() %>%
  # rename column names
  dplyr::rename("point" = "V1",
                "lon" = "V2",
                "lat" = "V3") %>%
  # convert to simple feature
  sf::st_as_sf(coords = c("lon", "lat"),
               # set the coordinate reference system to WGS84
               crs = "EPSG:4326") %>%
  # change projection to NAD83 UTM 11N (EPSG::26911)
  sf::st_transform(x = .,
                   crs = crs) # EPSG 26911 (https://epsg.io/26911))

# create polygon
aoi_poly <- aoi_points %>%
  # group by the points field
  dplyr::group_by(point) %>%
  # combine geometries without resolving borders to create multipoint feature
  dplyr::summarise(geometry = st_combine(geometry)) %>%
  # convert back to sf
  sf::st_as_sf() %>%
  # convert to polygon simple feature
  sf::st_cast("POLYGON") %>%
  # convert back to sf
  sf::st_as_sf()

## check units for determining cellsize of grid (units will be in meters)
sf::st_crs(aoi_poly, parameters = TRUE)$units_gdal

## plot
plot(aoi_poly)

#####################################
#####################################

# create larger study region

aoi_setback <- aoi_poly %>%
  # apply the 1-nautical mile setback to create the larger study region
  sf::st_buffer(x = .,
                # setback = 1-nautical mile
                dist = setback)

#####################################
#####################################

# export data
sf::st_write(obj = aoi_points, dsn = output_gpkg, layer = stringr::str_glue("{region_name}_{mariculture_site}_points"), append = F)
sf::st_write(obj = aoi_poly, dsn = output_gpkg, layer = stringr::str_glue("{region_name}_{mariculture_site}_polygon"), append = F)
sf::st_write(obj = aoi_setback, dsn = output_gpkg, layer = stringr::str_glue("{region_name}_{mariculture_site}_study_region"), append = F)

#####################################
#####################################

# calculate end time and print time difference
print(Sys.time() - start) # print how long it takes to calculate