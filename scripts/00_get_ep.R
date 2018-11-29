library(dplyr)
library(magrittr)
library(LAGOSNE)

lg           <- lagosne_load()
date_start   <- as.Date("2000-01-01")
date_end     <- as.Date("2010-01-01")
min_sample_n <- 3
ag_cutoff    <- 0.4
min_state_n  <- 4
max_iws_ha   <- 190000
max_lake_area_ha <- 40000

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

saveRDS(ep_nutr, "data/ep_nutr.rds")
