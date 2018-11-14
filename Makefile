.PHONY: all figures data

all: data figures

data: data/gis.gpkg

data/gis.gpkg: scripts/00_get_gis.R
	Rscript $<

figures: data figures/size_comparison.pdf

figures/size_comparison.pdf: scripts/03_viz.R
	Rscript $<
