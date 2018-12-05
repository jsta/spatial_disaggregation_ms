
# ---- source_utils ----

library(sp)
suppressMessages(library(dplyr))
library(gstat)
library(ggplot2)
library(sf)
library(LAGOSextra)
library(LAGOSNE)
library(lwgeom)
library(classInt)
library(tidyr)
library(stringr)
library(cowplot)
library(mapview)
library(macroag)

theme_opts <- theme(axis.text = element_blank(),
                    axis.ticks = element_blank(),
                    panel.background = element_blank(),
                    legend.text = element_text(size = 8),
                    legend.title = element_text(size = 10),
                    legend.key.size = unit(0.7, "line"),
                    plot.margin = unit(c(0, -0.13, 0, -0.13), "cm"))
                    # plot.margin = unit(c(0, 0, -2, 0), "cm")) # t, r, b, l

signif_star <- function(x){
  if(!is.na(x)){
    if(x){
      "*"
    }else{
      ""
    }
  }else{
    ""
  }
}

county_sf <- function(){
  county_sf        <- st_as_sf(maps::map("county", fill = TRUE, plot = FALSE))
  county_sf        <- tidyr::separate(county_sf, ID, c("state", "county"), ",")
  county_sf$county <- gsub("\\.", "", gsub(" ", "", county_sf$county))
  county_sf        <- st_make_valid(county_sf)

  county_key <- data.frame(state = tolower(state.name), state_abb = state.abb,
                           stringsAsFactors = FALSE)
  county_sf <- left_join(county_sf, county_key)
  # county_sf <- county_sf[
  #   unlist(lapply(
  #     st_intersects(county_sf, iws),
  #     function(x) length(x) > 0)),]
  county_sf
}

state_sf <- function(){
  state_sf <- st_as_sf(maps::map("state", fill = TRUE, plot = FALSE))
  key <- data.frame(ID = tolower(state.name),
                    ABB = state.abb, stringsAsFactors = FALSE)
  left_join(state_sf, key, by = "ID")
}

get_states <- function(bbox){
  state_sf <- sf::st_as_sf(maps::map("state", fill = TRUE, plot = FALSE))
  key <- data.frame(ID = tolower(state.name),
                    ABB = state.abb, stringsAsFactors = FALSE)
  state_sf <- left_join(state_sf, key, by = "ID")
  bbox <- st_transform(st_as_sfc(bbox), st_crs(state_sf))

  state_sf <- state_sf[unlist(lapply(
    st_intersects(state_sf, bbox),
    function(x) length(x) > 0)),]

  state_sf$ABB
}

Rmd_bind <- function(dir = ".",
           book_header = readLines(textConnection("---\ntitle: 'Title'\n---")))
  {
    old <- setwd(dir)
    if(length(grep("book.Rmd", list.files())) > 0){
      warning("book.Rmd already exists")
    }
    write(book_header, file = "book.Rmd", )
    cfiles <- list.files(pattern = "*.Rmd", )
    ttext <- NULL
    for(i in 1:length(cfiles)){
      text <- readLines(cfiles[i])
      hspan <- grep("---", text)
      text <- text[-c(hspan[1]:hspan[2])]
      write(text, sep = "\n", file = "book.Rmd", append = T)
    }
    rmarkdown::render("book.Rmd", output_format = "pdf_document")
    setwd(old)
  }
