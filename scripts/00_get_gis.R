# setwd("../")
source("scripts/99_utils.R")
# source("01_prepdata.R")

# ---- size_comparison ----
lg   <- lagosne_load()

ep <- readRDS("~/Documents/Science/JournalSubmissions/lagos_ag/data/ep.rds") %>%
  st_as_sf(coords = c("nhd_long", "nhd_lat"), crs = 4326)

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
  dplyr::select(starts_with("state"), hu4_zoneid) %>%
  tidyr::gather(key = "state", value = "value", -hu4_zoneid) %>%
  dplyr::filter(value %in% state_codes) %>%
  distinct(hu4_zoneid)

hu4s <- LAGOSextra::query_gis("HU4", "ZoneID", hu4_zones$hu4_zoneid)
iws  <- LAGOSextra::query_gis("IWS", "lagoslakeid", ep$lagoslakeid)

hu8_zones <- lg$hu8 %>%
  mutate(hu8_states = gsub("  ", "NA", sprintf("%-8s", hu8_states, "NA"))) %>%
  tidyr::separate(hu8_states, into = paste0("state_", 1:4), sep = seq(2, 6, 2)) %>%
  dplyr::select(starts_with("state"), hu8_zoneid) %>%
  tidyr::gather(key = "state", value = "value", -hu8_zoneid) %>%
  dplyr::filter(value %in% state_codes) %>%
  distinct(hu8_zoneid)

hu8s <- LAGOSextra::query_gis("HU8", "ZoneID", hu8_zones$hu8_zoneid)

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
