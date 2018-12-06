#' extract_rsource.R
#' =======================================================
#+ setup, include=FALSE
knitr::opts_chunk$set(eval = FALSE)
#+

# code_source
fl <- c("scripts/99_utils.R", "scripts/00_get_gis.R", "scripts/00_get_ep.R",
        "scripts/hpcc.R", "manuscript/code-pdf_source/extract_rsource.R")

sapply(fl, function(x) {
  # x <- fl[1]
  knitr::spin(x, knit = TRUE, report = FALSE)
  root <- stringr::str_extract(basename(x), "(.*)(?=.R)")
  from <- paste0(root, ".md")
  dest <- paste0("manuscript/code-pdf_source/", root, ".md")
  file.rename(from, dest)
  })

# figures_source
fl <- list.files("figures/", pattern = "*.Rmd",
                 full.names = TRUE, include.dirs = TRUE)

source("scripts/99_utils.R")
sapply(fl, function(x) {
  # x <- fl[2]
  f_temp   <- paste0("manuscript/figures-pdf_source/", basename(x))
  root     <- stringr::str_extract(basename(x), "(.*)(?=.Rmd)")
  from     <- paste0(root, ".md")
  from_rmd <- paste0("manuscript/figures-pdf_source/", root, ".Rmd")
  dest     <- paste0("manuscript/figures-pdf_source/", root, ".R")
  dest_md  <- paste0("manuscript/figures-pdf_source/", root, ".md")

  file.copy(x, f_temp)
  backstitch(f_temp, outfile = dest, output_type = "script")
  unlink(from_rmd)
  knitr::spin(dest, knit = TRUE, report = FALSE)
  file.rename(from, dest_md)
})
