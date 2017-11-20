library(here)
library(readr)
library(ggplot2)
library(cowplot)
library(viridis)
library(RColorBrewer)
library(scales)
library(ggthemes)
library(tidyr)
library(dplyr, warn.conflicts = FALSE)

## Ingest 
# load data
# calendar quarter, case ordinal, door2_contact, door2_ct, ct2_read, cbc2_result, inr2_result, tpa2_deliver
col_names <- c('quarter','case','month','d2_dr','d2_ct','ct2_r','cbc2_r','inr2_r','d2_n','tpa2_d')
col_spec <- cat('i','c',rep('i',7), sep='')
col_spec <- cols(
  quarter = col_integer(),
  case = col_integer(),
  month = col_integer(),
  d2_dr = col_integer(),
  d2_ct = col_integer(),
  ct2_r = col_skip(),
  cbc2_r = col_skip(),
  inr2_r = col_skip(),
  d2_n = col_integer(),
  tpa2_d = col_skip()
)

file_path <- file.path( here(), 'data', 'tpa_input.csv')
df <- read_csv( file_path, skip = 1, col_names = col_names, col_types = col_spec )

## Transform data.
# Prepent Q to timepoint
#df_mod <- df %>% mutate(quarter=paste0('Q',quarter))
# lookup
lkup <- data.frame(quarter=as.factor(c(1,2,3,4)), name=c('Q1', 'Q2', 'July-Aug', 'Sept'))

df_mod <- df
df_mod$quarter[!is.na(df_mod$month)] <- 4
df_mod$quarter <- as.factor(df_mod$quarter)
df_mod <- left_join(df_mod, lkup) %>% select(-month, -quarter, quarter=name)
df_mod$quarter <- factor(df_mod$quarter,levels(df_mod$quarter)[c(2,3,1,4)])

# Convert category columns (all but quarter and case_ord) to 
df_cnt <- df_mod %>%
  group_by(quarter) %>%
  summarise_all(funs(sum(!is.na(.)))) %>%
  gather(evt, count, -quarter)

df_med <- df_mod %>%
  group_by(quarter) %>%
  summarise_all(funs(median),na.rm=T) %>%
  gather(evt, median, -quarter)

plot_data <- inner_join(df_med,df_cnt) %>% filter(evt != "case")

# Rename events
evt_lookup <- data.frame(
  'from'=c('d2_dr','d2_ct','d2_n'), 
  'to'=c('Door to Doctor', 'Door to Head CT', 'Door to Treatment'))
plot_data <- plot_data %>% mutate(evt=evt_lookup$to[match(evt, evt_lookup$from)])

### PLOTTING

## Calculate Scales
# half the value of maxium door to needle median
d2rx_h_max <- max(plot_data$median[plot_data$evt == "Door to Treatment"]) /2
# Maximum value of remaining events * 1.1
d2o_max <- max(plot_data$median[plot_data$evt != "Door to Treatment"]) * 1.1
# Scale max for other plots will be whichever is greater
y_scale_max <- max(c(d2rx_h_max, d2o_max))

## General Plot
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
    breaks = levels(plot_data$evt),
    name="Event"
  )
plot

# Make Palrette
pal <- c(brewer.pal(5, "Set1")[c(1,3,4,5)], brewer.pal(5, "Pastel1")[c(2,5,1,3)])
pal <- brewer.pal(8,"Set2")

## Door to Treatment Plot
df_d2rx <- plot_data %>% filter(evt == "Door to Treatment")
plot_d2rx <- ggplot(df_d2rx, aes(x = quarter, y = median)) +
  geom_col(aes(fill = evt), color="black") +
  scale_y_continuous(breaks=pretty_breaks()) +
  labs(title = "Door to Treatment", x = "Period", y = "Time (minutes)") +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none"
  ) +
  scale_fill_manual(values=pal[3]) 
plot_d2rx

## Facetted other plots
df_o <- plot_data %>% filter(evt != "Door to Treatment")
plot_o <- ggplot(df_o, aes(x = quarter, y = median)) +
  geom_col(aes(fill = evt), color="black") +
  facet_wrap(~evt, nrow=2, scales="free_x", strip.position = 'top') +
  scale_y_continuous(limits=c(0, y_scale_max), breaks=pretty_breaks()) +
  labs(x = "Period", y = "Time (minutes)") +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none",
    axis.line=element_line()
  ) +
  scale_fill_brewer(palette=2) 
plot_o

## Door to Head CT
df_ct <- plot_data %>% filter(evt == "Door to Head CT")
plot_ct <- ggplot(df_ct, aes(x = quarter, y = median)) +
  geom_col(aes(fill = evt), color="black") +
  scale_y_continuous(limits=c(0, y_scale_max), breaks=pretty_breaks()) +
  labs(title = "Door to Head CT", x = "Period", y = "Time (minutes)") +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none"
  ) +
  scale_fill_manual(values=pal[2]) 
plot_ct

# Door to Doctor
df_dr <- plot_data %>% filter(evt == "Door to Doctor")
plot_dr <- ggplot(df_dr, aes(x = quarter, y = median)) +
  geom_col(aes(fill = evt), color="black") +
  scale_y_continuous(limits=c(0, y_scale_max), breaks=pretty_breaks()) +
  labs(title = "Door to Doctor", x = "Period", y = "Time (minutes)") +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "none"
  ) +
  scale_fill_manual(values=pal[3]) 
plot_dr

# Combine Plots
# Manual combo of three plots
ogrid <- plot_grid(plot_ct, plot_dr, nrow=2, ncol=1, rel_widths = c(1,1))
plot_grid(plot_d2rx, ogrid, nrow=1, ncol=2, rel_widths = c(1,1))

# Combo of main plot and a facetted plot
plot_grid(plot_d2rx, plot_o)

