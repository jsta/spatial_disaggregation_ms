.PHONY: all figures data

all: manuscript/all.pdf

manuscript/all.pdf: data figures manuscript/figures_source.pdf
	pdftk manuscript/figures.pdf manuscript/figures_source.pdf manuscript/code_source.pdf cat output manuscript/all.pdf

manuscript/manuscript.pdf: manuscript/manuscript.Rmd \
manuscript/pinp.cls \
manuscript/jsta.bst
	cd manuscript && make manuscript.pdf

data: data/gis.gpkg data/ep_nutr.rds data/counties_tillage.rds

data/gis.gpkg: scripts/00_get_gis.R
	Rscript $<

data/counties_tillage.rds: scripts/00_get_gis.R
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

manuscript/code_source.pdf: manuscript/code-pdf_source/extract_rsource.R manuscript/figures.pdf manuscript/code-pdf_source/hpcc_job.Rmd
	-rm manuscript/code-pdf_source/code.md
	Rscript $<
	Rscript -e "rmarkdown::render('manuscript/code-pdf_source/hpcc_job.Rmd')"
	pandoc -o manuscript/code-pdf_source/code.md manuscript/code-pdf_source/*.md
	pandoc -o $@ manuscript/code-pdf_source/code.md

manuscript/figures_source.pdf: manuscript/code_source.pdf
	-rm manuscript/figures-pdf_source/figures.md
	pandoc -o manuscript/figures-pdf_source/figures.md manuscript/figures-pdf_source/*.md
	pandoc -o $@ manuscript/figures-pdf_source/figures.md
