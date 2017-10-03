library(here)
library(readr)
library(ggplot2)

## Ingest 
# load data
col_names <- c('quarter','case_ord','d2_contact','d2_ct','ct2_read','cbc2_result','inr2_result','d2_needle','tpa2_deliver')
col_spec <- cat('i','c',rep('i',7), sep='')
col_spec <- cols(
  quarter = col_integer(),
  case_ord = col_integer(),
  d2_contact = col_integer(),
  d2_ct = col_integer(),
  ct2_read = col_integer(),
  cbc2_result = col_integer(),
  inr2_result = col_integer(),
  d2_needle = col_integer(),
  tpa2_deliver = col_integer()
)

file_path <- file.path( here(), 'data', 'tpa_input.csv')
df <- read_csv( file_path, skip = 1, col_names = col_names, col_types = col_spec )

## Plot Data
plot_data <- df

# plot <- ggplot(plot_data, aes(x = time, y = count)) +
#   facet_grid(discord ~ .) +
#   geom_col(aes(fill = discord), color="black") +
#   scale_y_continuous(breaks=pretty_breaks()) +
#   labs(title = plot_title, x = "time period", y = "count") +
#   theme(
#     panel.grid.minor = element_blank(),
#     legend.position = "none"
#   ) +
#   scale_fill_viridis(
#     discrete = TRUE,
#     breaks = levels(plot_data$discord)
#   )
