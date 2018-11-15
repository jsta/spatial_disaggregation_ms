# setwd("scripts")
source("scripts/99_utils.R")
# source("01_prepdata.R")

# ---- size_comparison ----
gpkg_path <- "data/gis.gpkg"
states   <- st_read(gpkg_path, layer = "states")
hu4s     <- st_read(gpkg_path, layer = "hu4s")
hu8s     <- st_read(gpkg_path, layer = "hu8s")
counties <- st_read(gpkg_path, layer = "counties")
iws      <- st_read(gpkg_path, layer = "iws")

q          <- seq(0, 1, length.out = 20)
res        <- lapply(list(hu4s, counties, states, iws, hu8s),
              function(x) as.numeric(quantile(st_area(x), probs = q)))
names(res) <- c("hu4", "county", "state", "iws", "hu8s")
res        <- dplyr::bind_rows(res) %>%
  mutate(q = q) %>%
  tidyr::gather(key = "scale", value = "area", -q)


theme_opts <- theme_minimal() +
  theme(axis.title = element_text(size = 16),
        axis.text = element_text(size = 16),
        legend.text = element_text(size = 14))
g <- ggplot() +
  geom_line(data = res, aes(x = area, y = rev(q), color = scale), size = 1.5) +
  ylab("Density") + xlab("Area (m2)") +
  scale_x_continuous(labels = c("10^2", "10^11"),
                     breaks = c(10^2, 10^11)) +
  theme_opts +
  labs(color = "")
ggsave("figures/size_comparison.pdf")

# ---- ag_practice_line-plots ----

# library(macroag)
#
# data("tillage_ctic")
# tillage_ctic <- dplyr::filter(tillage_ctic, huc8_n %in% as.character(hu8s$HUC8))
#
# plot(tillage_ctic$totacre, tillage_ctic$notill)
# abline(0, 1)

