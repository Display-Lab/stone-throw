library(here)
library(readr)
library(ggplot2)
library(viridis)
library(scales)
library(ggthemes)
library(tidyr)
library(dplyr, warn.conflicts = FALSE)

## Ingest 
# load data
# calendar quarter, case ordinal, door2_contact, door2_ct, ct2_read, cbc2_result, inr2_result, tpa2_deliver
col_names <- c('quarter','case','d2_dr','d2_ct','ct2_r','cbc2_r','inr2_r','d2_n','tpa2_d')
col_spec <- cat('i','c',rep('i',7), sep='')
col_spec <- cols(
  quarter = col_integer(),
  case = col_integer(),
  d2_dr = col_integer(),
  d2_ct = col_integer(),
  ct2_r = col_integer(),
  cbc2_r = col_integer(),
  inr2_r = col_integer(),
  d2_n = col_integer(),
  tpa2_d = col_integer()
)

file_path <- file.path( here(), 'data', 'tpa_input.csv')
df <- read_csv( file_path, skip = 1, col_names = col_names, col_types = col_spec )

## Transform data.
# Convert category columns (all but quarter and case_ord) to 
df_cnt <- df %>% group_by(quarter) %>% summarise_all(funs(sum(!is.na(.)))) %>% gather(evt, count, -quarter)
df_med <- df %>% group_by(quarter) %>% summarise_all(funs(median),na.rm=T) %>% gather(evt, median, -quarter)
plot_data <- inner_join(df_med,df_cnt) %>% filter(evt != "case")

## Plot Data
plot <- ggplot(plot_data, aes(x = quarter, y = median)) +
  facet_grid(~evt, scales="free") +
  geom_col(aes(fill = evt), color="black") +
  scale_y_continuous(breaks=pretty_breaks()) +
  labs(title = "Time2Event", x = "Quarter", y = "Median Duration") +
  theme(
    panel.grid.minor = element_blank()
  ) +
  scale_fill_viridis(
    discrete = TRUE,
    breaks = levels(plot_data$evt)
  )
plot

## D2N
df_d2n <- plot_data %>% filter(evt == "d2_n")
plot_d2n <- ggplot(df_d2n, aes(x = quarter, y = median)) +
  geom_col(aes(fill = evt), color="black") +
  scale_y_continuous(breaks=pretty_breaks()) +
  labs(title = "Door to Needle", x = "Quarter", y = "Median Duration") +
  theme(
    panel.grid.minor = element_blank()
  ) +
  scale_fill_viridis(
    discrete = TRUE,
    breaks = levels(plot_data$evt)
  )
plot_d2n

## Others
df_other <- plot_data %>% filter(evt != "d2_n")
plot_o <- ggplot(df_other, aes(x = quarter, y = median)) +
  facet_grid(evt~.) +
  geom_col(aes(fill = evt), color="black") +
  scale_y_continuous(breaks=pretty_breaks()) +
  labs(title = "Time2Event", x = "Quarter", y = "Median Duration") +
  theme(
    panel.grid.minor = element_blank()
  ) +
  scale_fill_brewer(
    breaks = levels(plot_data$evt)
  )
plot_o
