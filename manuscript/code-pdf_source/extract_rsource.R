#' extract_rsource.R
#' =======================================================
#+ setup, include=FALSE
knitr::opts_chunk$set(eval = FALSE)
#+

fl <- c("scripts/99_utils.R", "scripts/00_get_gis.R", "scripts/00_get_ep.R",
        "scripts/hpcc.R", "manuscript/code-pdf_source/extract_rsource.R")
# fl <- paste0("../../", fl)

sapply(fl, function(x) {
  # x <- fl[1]
  knitr::spin(x, knit = TRUE, report = FALSE)
  root <- stringr::str_extract(basename(x), "(.*)(?=.R)")
  from <- paste0(root, ".md")
  dest <- paste0("manuscript/code-pdf_source/", root, ".md")
  file.rename(from, dest)
  })
