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

hu4s <- LAGOSNEgis::query_gis("HU4", "ZoneID", hu4_zones$hu4_zoneid)
hu8s <- LAGOSNEgis::query_gis_(
  query = paste0("SELECT * FROM HU8 WHERE ",
                 paste0("HUC8 LIKE '", hu4s$HUC4, "%'", collapse = " OR ")))

# unlink("data/gis.gpkg")
# st_layers("data/gis.gpkg")
gpkg_path <- "data/gis.gpkg"
st_write(states, gpkg_path, layer = "states",
         layer_options = c("OVERWRITE=yes"))
st_write(hu4s, gpkg_path, layer = "hu4s", update = TRUE,
         layer_options = c("OVERWRITE=yes"))
st_write(hu8s, gpkg_path, layer = "hu8s", update = TRUE,
         layer_options = c("OVERWRITE=yes"))
st_write(counties, gpkg_path, layer = "counties", update = TRUE,
         layer_options = c("OVERWRITE=yes"))
st_write(iws, gpkg_path, layer = "iws", update = TRUE,
         layer_options = c("OVERWRITE=yes"))

# ---- tillage_data ----
data("tillage_ctic")
hu4s      <- st_read(gpkg_path, layer = "hu4s")
hu8s      <- st_read(gpkg_path, layer = "hu8s")
states    <- st_read(gpkg_path, layer = "states")
counties  <- st_read(gpkg_path, layer = "counties")
lg        <- lagosne_load()

n_cat      <- 4
colors     <- c("red", "yellow", "blue", "green")
break_cuts <- c(0, 10, 25, 50, 100)

tc <- dplyr::filter(tillage_ctic, huc8_n %in% as.character(hu8s$HUC8)) %>%
  left_join(dplyr::select(lg$hu8, hu8, hu8_zoneid),
            by = c("huc8_n" = "hu8")) %>%
  dplyr::filter(year == 2004 & crop == "allcrops")
hu8s <- dplyr::left_join(hu8s, tc, by = c("ZoneID" = "hu8_zoneid"))
hu8s    <- mutate(hu8s,
                  pctnotil_cat = cut(hu8s$pctnotil, breaks = break_cuts))
hu8s <- dplyr::filter(hu8s, !is.na(pctnotil))
saveRDS(hu8s, "data/hu8_tillage.rds")

if(!file.exists("data/counties_tillage.rds")){
  counties <- st_transform(counties, st_crs(hu8s))
  counties <- st_cast(counties, "MULTIPOLYGON")
  counties <- sf::st_interpolate_aw(hu8s["pctnotil"], counties, extensive = FALSE)
  counties <- mutate(counties,
                     pctnotil_cat = cut(counties$pctnotil, breaks = break_cuts))
  saveRDS(counties, "data/counties_tillage.rds")
}

if(!file.exists("data/hu4_tillage.rds")){
  hu4_pctnotil <- hu8s %>%
    mutate(HUC4 = substring(HUC8, 0, 4)) %>%
    mutate(notilarea_j = pctnotil * Shape_Area) %>%
    group_by(HUC4) %>%
    summarize(pctnotil = sum(notilarea_j, na.rm = TRUE) / sum(Shape_Area)) %>%
    st_drop_geometry()

  hu4s <- hu4s %>%
    left_join(hu4_pctnotil) %>%
    mutate(pctnotil_cat = cut(pctnotil, breaks = break_cuts))
  saveRDS(hu4s, "data/hu4_tillage.rds")
}
