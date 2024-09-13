#########################
### 02. AIS transects ###
#########################

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

## year directory
year <- "2023"
month <- "12"
region <- "wc"

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
### west coast AIS data
data_dir <- file.path("data/a_raw_data/", stringr::str_glue("{region}_ais_transect.gpkg"))

### output geopackage
output_gpkg <- file.path("data/b_intermediate_data/", stringr::str_glue("{region}_ais_transect.gpkg"))

#####################################

# inspect layers within geopackage
sf::st_layers(dsn = data_dir,
              do_count = T)

#####################################
#####################################

# load data
ais_data <- sf::st_read(dsn = data_dir,
                        layer = sf::st_layers(dsn = data_dir)[[1]][grep(pattern = stringr::str_glue("{year}{month}"),
                                                                      x = sf::st_layers(dsn = data_dir)[[1]])]) %>%
  sf::st_transform(x = .,
                   crs = crs)

## check units for determining cellsize of grid (units will be in meters)
sf::st_crs(ais_data, parameters = TRUE)$units_gdal

#####################################
#####################################

# export data
sf::st_write(obj = ais_data, dsn = output_gpkg, layer = stringr::str_glue("{region}_{year}{month}_transects"), append = F)

#####################################
#####################################

# calculate end time and print time difference
print(Sys.time() - start) # print how long it takes to calculate