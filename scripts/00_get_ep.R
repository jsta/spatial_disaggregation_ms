suppressMessages(library(dplyr))
library(magrittr)
library(LAGOSNE)
library(sf)
suppressMessages(library(tidyr))

lg           <- lagosne_load()
date_start   <- as.Date("2000-01-01")
date_end     <- as.Date("2010-01-01")
min_sample_n <- 3
ag_cutoff    <- 0.4
min_state_n  <- 4
max_iws_ha   <- 190000
max_lake_area_ha <- 40000

hu4_tillage      <- readRDS("data/hu4_tillage.rds")
hu8_tillage      <- readRDS("data/hu8_tillage.rds")
counties_tillage <- readRDS("data/counties_tillage.rds")

fix_wi_lkls <- function(lg){
  lg$tkn[which(lg$programname=="WI_LKLS")] <-
    lg$tkn[which(lg$programname=="WI_LKLS")] * 1000

  lg$no2no3[which(lg$programname=="WI_LKLS")] <-
    lg$no2no3[which(lg$programname=="WI_LKLS")] * 1000

  lg
}

calculate_tn <- function(lg){
  lg$tn_calculated <- lg$tkn + lg$no2no3
  lg$tn_combined   <- lg$tn
  lg$tn_combined[which(is.na(lg$tn_combined) == TRUE)] <-
    lg$tn_calculated[which(is.na(lg$tn_combined) == TRUE)]
  lg$tn <- lg$tn_combined
  lg
}

# filter ep with tn/tp data meeting date and n constraints
ep_nutr <- lg$epi_nutr %>%
  fix_wi_lkls() %>%
  calculate_tn() %>%
  dplyr::select(lagoslakeid, sampledate, tp, tn, no2no3) %>%
  dplyr::filter(!is.na(tp) | !is.na(tn) | !is.na(no2no3)) %>%
  group_by(lagoslakeid) %>%
  filter(sampledate > date_start & sampledate < date_end) %>%
  mutate(count = n(), min_date = min(sampledate), max_date = max(sampledate)) %>%
  filter(count > min_sample_n) %>%
  summarize(tp = median(tp, na.rm = TRUE),
            tn = median(tn, na.rm = TRUE),
            no2no3 = median(no2no3, na.rm = TRUE)) %>%
  identity()

ep_nutr <- ep_nutr %>%
  left_join(dplyr::select(lg$lakes_limno, lagoslakeid, maxdepth),
            "lagoslakeid") %>%
  drop_na(maxdepth)

saveRDS(ep_nutr, "data/ep_nutr.rds")

range01     <- function(x, ...){(x - min(x, ...)) / (max(x, ...) - min(x, ...))}
tillage_hu8 <- readRDS("data/hu8_tillage.rds")
ep_fake     <- tillage_hu8 %>%
  st_drop_geometry() %>%
  dplyr::select(ZoneID, HUC8, pctnotil) %>%
  mutate(ep_fake = range01((pctnotil / 100) +
                             rnorm(nrow(tillage_hu8), sd = 0.2)) * 100) %>%
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
  left_join(dplyr::select(st_drop_geometry(counties_tillage), county_zoneid, pctnotil),
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
