.PHONY: all figures data

all: data figures

data: data/gis.gpkg data/ep_nutr.rds data/counties_tillage.rds

data/gis.gpkg: scripts/00_get_gis.R
	Rscript $<

data/counties_tillage.rds: scripts/00_get_gis.R
	Rscript $<

data/ep_nutr.rds: scripts/00_get_ep.R
	Rscript $<

data/ep_fake.rds: scripts/00_get_ep.R data/hu8_tillage.rds
	Rscript $<

figures: data manuscript/figures.pdf

manuscript/figures.pdf: manuscript/figures.Rmd figures/01_size-comparison-1.pdf figures/02_tillage_map-1.pdf figures/03_scatter_plot-1.pdf figures/04_variograms-1.pdf
	Rscript -e "rmarkdown::render('$<', output_format = 'pdf_document')"
	-pdftk manuscript/figures.pdf cat 2-end output manuscript/figures2.pdf
	-mv manuscript/figures2.pdf manuscript/figures.pdf

figures/01_size-comparison-1.pdf: figures/01_size-comparison.Rmd
	Rscript -e "rmarkdown::render('$<', output_format = 'pdf_document')"

figures/02_tillage_map-1.pdf: figures/02_tillage_map.Rmd
	Rscript -e "rmarkdown::render('$<', output_format = 'pdf_document')"

figures/03_scatter_plot-1.pdf: figures/03_scatter_plot.Rmd
	Rscript -e "rmarkdown::render('$<', output_format = 'pdf_document')"

figures/04_variograms-1.pdf: figures/04_variograms.Rmd
	Rscript -e "rmarkdown::render('$<', output_format = 'pdf_document')"
