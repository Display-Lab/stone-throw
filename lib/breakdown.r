library(here)
library(readr)
library(ggplot2)
library(ggthemes)
library(scales)
library(RColorBrewer)
library(cowplot, warn.conflicts = F)
library(viridis)
library(tidyr)
library(dplyr, warn.conflicts = FALSE)
library(lubridate, warn.conflicts = FALSE)

# load data
# calendar quarter, case ordinal, door2_contact, door2_ct, ct2_read, cbc2_result, inr2_result, tpa2_deliver
col_names <- c('year','month','case','d2_dr','d2_ct','ct2_r','cbc2_r','inr2_r','d2_n','tpa2_d')
col_spec <- cols(
  year = col_integer(),
  month = col_integer(),
  case = col_integer(),
  d2_dr = col_integer(),
  d2_ct = col_integer(),
  ct2_r = col_skip(),
  cbc2_r = col_skip(),
  inr2_r = col_skip(),
  d2_n = col_integer(),
  tpa2_d = col_skip()
)

file_path <- file.path( here::here(), 'input', 'tPA_case_data_processed.csv')
df <- read_csv( file_path, skip = 1, col_names = col_names, col_types = col_spec )

## Add a date column
df2 <- df %>% mutate(date=make_date(year, month))

# Generate an axis label given the start and end of an interval
label_interval <- function(start, end){
  ys <- unique( c(year(start),year(end)) )
  ms <- c(as.character(month(start, abbr=T, label=T)),
          as.character(month(end, abbr=T, label=T)))
  line_one <- paste0(ms,collapse='-')
  line_two <- paste(ys,collapse=' ')
  paste0(line_one,"\n",line_two)
}

# Given vector of dates, 
# Return table with group boundaries an labels
time_group_table <- function(dates){
  min_month <- floor_date(min(dates), "months")
  max_month <- floor_date(max(dates), "months")
  num_months <- interval(min(dates),max(dates)) %/% months(1)
  num_groups <- floor(num_months / 3)
  
  #Build interval table
  end_months <- rev(seq(max_month, by="-1 quarters", length.out = num_groups))
  ends <- ceiling_date(end_months, unit="months") - days(1)
  starts <- end_months %m-% months(2)
  labels <- mapply(label_interval, starts, ends, SIMPLIFY = T)
  
  mm <- data.frame(start=starts, 
                   end=ends, 
                   quarter=c(1:length(ends)),
                   label=labels)
}

# Function to look up the quarter from a lookup table
lookup <- function(d,tbl){
  row_mask <- d >= tbl$start & d <= tbl$end
  ifelse(any(row_mask), tbl[row_mask, 'quarter'], NA)
}

# Build lookup table
lkup_tbl <- time_group_table(df2$date)

# use lookup table to add column for tracking the quarter
df2$quarter <- sapply(df2$date, FUN=lookup, lkup_tbl)

# Remove rows that don't fall into a rolling quarter
# Remove other date columns
df_mod <- df2 %>%
  select( -month, -year, -date ) %>%
  filter( !is.na(quarter))

# Convert category columns (all but quarter and case_ord) to 
df_cnt <- df_mod %>%
  group_by(quarter) %>%
  summarise_all(funs(sum(!is.na(.)))) %>%
  gather(evt, count, -quarter)

df_med <- df_mod %>%
  group_by(quarter) %>%
  summarise_all(funs(median),na.rm=T) %>%
  gather(evt, median, -quarter)

pd <- inner_join(df_med,df_cnt) %>% filter(evt != "case")

# Join lookup table to pull in quarter labels
# Rename events
evt_lookup <- data.frame(
  'from'=c('d2_dr','d2_ct','d2_n'), 
  'to'=c('Door to Doctor', 'Door to Head CT', 'Door to Treatment'))
plot_data <- pd %>% 
  left_join(lkup_tbl[,c('quarter','label')]) %>%
  mutate(evt=evt_lookup$to[match(evt, evt_lookup$from)],
         label=as.character(label),
         quarter=as.factor(quarter))


### PLOTTING

## Calculate Scales
# half the value of maxium door to needle median
d2rx_h_max <- max(plot_data$median[plot_data$evt == "Door to Treatment"]) /2
# Maximum value of remaining events * 1.1
d2o_max <- max(plot_data$median[plot_data$evt != "Door to Treatment"]) * 1.1
# Scale max for other plots will be whichever is greater
y_scale_max <- max(c(d2rx_h_max, d2o_max))

# Make Palrette
pal <- c(brewer.pal(5, "Set1")[c(1,3,4,5)], brewer.pal(5, "Pastel1")[c(2,5,1,3)])
pal <- brewer.pal(8,"Set2")

## Door to Treatment Plot
df_d2rx <- plot_data %>% filter(evt == "Door to Treatment")
plot_d2rx <- ggplot(df_d2rx, aes(x = quarter, y = median)) +
  geom_col(aes(fill = evt), color="black") +
  scale_x_discrete(labels=plot_data$label) +
  scale_y_continuous(breaks=pretty_breaks()) +
  labs(title = "Door to Treatment", x = NULL, y = "Time (minutes)") +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle=45,hjust=1),
    legend.position = "none"
  ) +
  scale_fill_manual(values=pal[3]) 

## Facetted other plots
df_o <- plot_data %>% filter(evt != "Door to Treatment")
plot_o <- ggplot(df_o, aes(x = quarter, y = median)) +
  geom_col(aes(fill = evt), color="black") +
  facet_wrap(~evt, nrow=2, scales="free_x", strip.position = 'top') +
  scale_y_continuous(limits=c(0, y_scale_max), breaks=pretty_breaks()) +
  scale_x_discrete(labels=plot_data$label) +
  labs(x = NULL, y = "Time (minutes)") +
  theme(
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle=45,hjust=1),
    axis.line=element_line(),
    legend.position = "none"
  ) +
  scale_fill_brewer(palette=2) 

# Combine Plots
# Combo of main plot and a facetted plot
pgrid <- plot_grid(plot_d2rx, plot_o)

# Write plot to file
plot_path <- file.path(here::here(), "door_to_events.png")
ggsave(plot_path, pgrid, device="png", width=10, height=7, units="in", dpi=72)
