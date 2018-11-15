.PHONY: all figures data

all: data figures

data: data/gis.gpkg

data/gis.gpkg: scripts/00_get_gis.R
	Rscript $<

figures: data manuscript/figures.pdf

manuscript/figures.pdf: manuscript/figures.Rmd figures/size_comparison.pdf
	Rscript -e "rmarkdown::render('$<', output_format = 'pdf_document')"
	-pdftk manuscript/figures.pdf cat 2-end output manuscript/figures2.pdf
	-mv manuscript/figures2.pdf manuscript/figures.pdf

figures/size_comparison.pdf: scripts/03_viz.R
	Rscript $<
