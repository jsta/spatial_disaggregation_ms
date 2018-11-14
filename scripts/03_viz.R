# setwd("scripts")
source("scripts/99_utils.R")
# source("01_prepdata.R")
library(ggridges)

# ---- size_comparison ----

ep <- readRDS("~/Documents/Science/JournalSubmissions/lagos_ag/data/ep.rds") %>%
  st_as_sf(coords = c("nhd_long", "nhd_lat"), crs = 4326)

states <- state_sf() %>%
  dplyr::filter(., ABB %in% c("IL", "IN", "IA", "MI", "MN", "MO", "NY", "OH", "PA", "WI"))

counties <- county_sf() %>%
  dplyr::filter(unlist(lapply(st_intersects(., states), function(x) length(x) > 0)))

hu4s <- LAGOSextra::query_gis("HU4", "ZoneID",
                              c("HU4_47","HU4_44","HU4_45","HU4_48","HU4_38","HU4_37","HU4_32","HU4_35","HU4_30","HU4_40","HU4_39","HU4_25","HU4_49","HU4_53","HU4_29","HU4_55","HU4_59","HU4_57","HU4_27","HU4_33","HU4_34","HU4_56","HU4_36","HU4_60","HU4_61","HU4_50","HU4_18","HU4_42","HU4_23","HU4_17","HU4_46","HU4_51","HU4_41","HU4_63","HU4_62","HU4_65","HU4_64","HU4_68","HU4_16","HU4_43"))

iws <- LAGOSextra::query_gis("IWS", "lagoslakeid", ep$lagoslakeid)

q          <- seq(0, 1, length.out = 20)
res        <- lapply(list(hu4s, counties, states, iws),
              function(x) as.numeric(quantile(st_area(x), probs = q)))
names(res) <- c("hu4", "county", "state", "iws")
res        <- dplyr::bind_rows(res) %>%
  mutate(q = q) %>%
  tidyr::gather(key = "scale", value = "area", -q)

ggplot() +
  geom_line(data = res, aes(x = area, y = rev(q), color = scale)) +
  ylab("Density")
