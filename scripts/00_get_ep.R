#' 00_get_ep.R
#' =======================================================
#+ setup, include=FALSE
knitr::opts_chunk$set(eval = FALSE)
#+


suppressMessages(library(dplyr))
library(magrittr)
library(LAGOSNE)
library(sf)
suppressMessages(library(tidyr))

range01     <- function(x, ...){(x - min(x, ...)) / (max(x, ...) - min(x, ...))}
tillage_hu8 <- readRDS("data/hu8_tillage.rds")
ep_fake     <- tillage_hu8 %>%
  st_drop_geometry() %>%
  dplyr::select(ZoneID, HUC8, pctnotil) %>%
  mutate(ep_fake = range01((pctnotil / 100) +
                             rnorm(nrow(tillage_hu8), sd = 0.1)) * 100) %>%
  dplyr::rename(hu8_zoneid = ZoneID) %>%
  dplyr::select(-pctnotil) %>%
  left_join(dplyr::select(lg$locus, lagoslakeid,
                          hu4_zoneid, hu8_zoneid,
                          county_zoneid, state_zoneid)) %>%
  left_join(dplyr::select(st_drop_geometry(hu4_tillage), ZoneID, pctnotil),
            by = c("hu4_zoneid" = "ZoneID")) %>%
  drop_na(pctnotil) %>%
  rename(pctnotil_hu4 = pctnotil) %>%
  left_join(dplyr::select(st_drop_geometry(hu8_tillage), ZoneID, pctnotil),
            by = c("hu8_zoneid" = "ZoneID")) %>%
  rename(pctnotil_hu8 = pctnotil) %>%
  left_join(dplyr::select(st_drop_geometry(counties_tillage),
                          county_zoneid, pctnotil),
            by = c("county_zoneid")) %>%
  drop_na(pctnotil) %>%
  rename(pctnotil_county = pctnotil) %>%
  left_join(dplyr::select(lg$hu4,
                          contains("zoneid"),
                          contains("_long"),
                          contains("_lat"))) %>%
  left_join(dplyr::select(lg$county,
                          contains("zoneid"),
                          contains("_long"),
                          contains("_lat"))) %>%
  left_join(dplyr::select(lg$hu8,
                          contains("zoneid"),
                          contains("_long"),
                          contains("_lat")))

saveRDS(ep_fake, "data/ep_fake.rds")
