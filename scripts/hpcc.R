#' hpcc.R
#' =======================================================
#+ setup, include=FALSE
knitr::opts_chunk$set(eval = FALSE)
#+


# Merge estimates of conservation tillage with geospatial polygons
# Duplicates the behavior of: $ make data/hu8_tillage.rds

# upload gis.gpkg
# make data/hu8_tillage.rds

if(Sys.getenv("RSTUDIO_USER_IDENTITY") != "jose"){ # on HPCC
  .libPaths("R")
}

suppressMessages(library(sf))
suppressMessages(library(dplyr))

library(macroag) # https://github.com/jsta/macroag
data("tillage_ctic")

gpkg_path <- "data/gis.gpkg"
hu8s      <- st_read(gpkg_path, layer = "hu8s", stringsAsFactors = FALSE)

break_cuts <- c(0, 10, 25, 50, 100)

tc   <- dplyr::filter(tillage_ctic, huc8_n %in% as.character(hu8s$HUC8)) %>%
        dplyr::filter(year == 2004 & crop == "allcrops")
hu8s <- dplyr::left_join(tc, hu8s, by = c("huc8_n" = "HUC8"))
hu8s <- mutate(hu8s,
                  pctnotil_cat = cut(hu8s$pctnotil, breaks = break_cuts))
hu8s <- dplyr::filter(hu8s, !is.na(pctnotil))

require(LAGOSNE)
tryCatch(
  if(dir.exists(LAGOSNE:::lagos_path())){
    lg <- lagosne_load()
    hu8s <- left_join(hu8s,
                      dplyr::select(lg$hu8, hu8, hu8_zoneid),
                      by = c("huc8_n" = "hu8"))
  }, error = function(e) NULL)

saveRDS(hu8s, "data/hu8_tillage.rds")
