# setwd("../")
source("scripts/99_utils.R")

# ---- size_comparison ----
lg   <- lagosne_load()

ep <- readRDS("~/Documents/Science/JournalSubmissions/lagos_ag/data/ep.rds") %>%
  st_as_sf(coords = c("nhd_long", "nhd_lat"), crs = 4326)

iws  <- LAGOSNEgis::query_gis("IWS", "lagoslakeid", ep$lagoslakeid)

state_codes <- c("IL", "IN", "IA",
                 "MI", "MN", "MO",
                 "NY", "OH", "PA", "WI")
states <- state_sf() %>%
  dplyr::filter(., ABB %in% state_codes)

counties <- county_sf() %>%
  dplyr::filter(unlist(lapply(st_intersects(., states),
                              function(x) length(x) > 0)))

# use LAGOSNE to pull hu ids that correspond to states
# lg <- lagosne_load()
# pad states with NA to 10 characters
hu4_zones <- lg$hu4 %>%
  mutate(hu4_states = gsub("  ", "NA", sprintf("%-10s", hu4_states, "NA"))) %>%
  tidyr::separate(hu4_states, into = paste0("state_", 1:5), sep = seq(2, 8, 2)) %>%
  dplyr::select(starts_with("state"), hu4_zoneid, hu4) %>%
  tidyr::gather(key = "state", value = "value", -hu4_zoneid, -hu4) %>%
  dplyr::filter(value %in% state_codes) %>%
  distinct(hu4, hu4_zoneid)

hu4s       <- lapply(state_codes,
               function(x) findWBD(getAOI(state = x),
                                   level = 4, crop = FALSE))
hu4s       <- lapply(hu4s, function(x) st_as_sf(x$huc4))
hu4s       <- lapply(hu4s, function(x){
                names(x)   <- c("objectid","tnmid","metasourceid",
                                "sourcedatadesc", "sourceoriginator",
                                "sourcefeatureid","loaddate","gnis_id",
                                "areaacres","areasqkm","states","huc4",
                                "name","shape_length","shape_area",
                                "geometry"); x
                })
hu4s       <- do.call("rbind", hu4s)
hu4s       <- dplyr::filter(hu4s, !duplicated(hu4s$huc4))
hu4s       <- dplyr::filter(hu4s, hu4s$huc4 %in% hu4_zones$hu4)
hu4s       <- st_transform(hu4s, st_crs(iws))
hu4s       <- left_join(hu4s,
                        dplyr::select(lg$hu4, hu4, hu4_zoneid),
                        by = c("huc4" = "hu4"))

# join zoneids


# hu4s <- LAGOSNEgis::query_gis("HU4", "ZoneID", hu4_zones$hu4_zoneid)

hu8_zones <- lg$hu8 %>%
  mutate(hu8_states = gsub("  ", "NA", sprintf("%-8s", hu8_states, "NA"))) %>%
  tidyr::separate(hu8_states, into = paste0("state_", 1:4), sep = seq(2, 6, 2)) %>%
  dplyr::select(starts_with("state"), hu8_zoneid, hu8) %>%
  tidyr::gather(key = "state", value = "value", -hu8_zoneid, -hu8) %>%
  dplyr::filter(value %in% state_codes) %>%
  distinct(hu8, hu8_zoneid)

hu8s       <- lapply(state_codes,
                     function(x) findWBD(getAOI(state = x),
                                         level = 8, crop = FALSE))
hu8s       <- lapply(hu8s, function(x) st_as_sf(x$huc8))
hu8s       <- lapply(hu8s, function(x){
  names(x)   <- tolower(names(x))
  x <- dplyr::select(x, huc8, states, geometry)
  x
})
hu8s       <- do.call("rbind", hu8s)
hu8s       <- dplyr::filter(hu8s, !duplicated(hu8s$huc8))

hu8s       <- dplyr::filter(hu8s, hu8s$huc8 %in% hu8_zones$hu8)
hu8s       <- st_transform(hu8s, st_crs(iws))
hu8s       <- left_join(hu8s,
                  dplyr::select(lg$hu8, hu8, hu8_zoneid),
                  by = c("huc8" = "hu8"))


# join zoneids

# hu8s <- LAGOSNEgis::query_gis("HU8", "ZoneID", hu8_zones$hu8_zoneid)

# unlink("data/gis.gpkg")
# st_layers("data/gis.gpkg")
gpkg_path <- "data/gis.gpkg"
st_write(states, gpkg_path, layer = "states", layer_options = c("OVERWRITE=yes"))
st_write(hu4s, gpkg_path, layer = "hu4s", update = TRUE,
         layer_options = c("OVERWRITE=yes"))
st_write(hu8s, gpkg_path, layer = "hu8s", update = TRUE,
         layer_options = c("OVERWRITE=yes"))
st_write(counties, gpkg_path, layer = "counties", update = TRUE,
         layer_options = c("OVERWRITE=yes"))
st_write(iws, gpkg_path, layer = "iws", update = TRUE,
         layer_options = c("OVERWRITE=yes"))
