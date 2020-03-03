# last known normal line plotting
library(tidyr)
library(ggplot2)
library(scales)
library(dplyr, warn.conflicts = FALSE)
library(here)
library(readr)
library(cowplot)

# Read raw data.

col_names <- c('grp','month',paste('bin',c(1:14),sep='_'), 'unk_1','unk_2','total', paste('stat',c(1:4), sep='_'))
# "grp"     "month" "bin_1"   "bin_2"   "bin_3"   "bin_4"  
# "bin_5"   "bin_6"   "bin_7"   "bin_8"   "bin_9"   "bin_10" 
# "bin_11"  "bin_12"  "bin_13"  "bin_14"  "unk_1"   "unk_2"  
# "total"   "stat_1"  "stat_2"  "stat_3"  "stat_4"

file_path <- file.path( here(), 'data', 'last_known_well.csv')
df <- read_csv( file_path, skip = 1, col_names = col_names)

# Munge raw data.
# Remove unused columns
# Strip out "helpful" percentages embedded in count data
# Add 'Q' and minor increments to time values (assuming they're in order)
# Convert the time bin variables to integers
df1 <- df %>%
  select(-grp, -starts_with('stat'), -starts_with('unk_')) %>%
  mutate_if(is.character, .funs='sub', pattern=' (.*)', replacement='') %>%
  mutate(month=factor(month.abb[month], levels=unique(month.abb[month]))) %>%
  mutate_at(vars(starts_with("bin_")), .funs=as.integer)

# Make plot data
# Sum the time bins as the numerator
# calculate the fraction of total cases with documented LKN
plot_data <- df1 %>% 
  group_by(month) %>%
  gather(key=time_bin, value=count, starts_with("bin_")) %>%
  group_by(month, total) %>% summarize(numer=sum(count)) %>%
  mutate(fract=numer/total)
  
# Make a line plot with point size indicating number of cases
plot <- ggplot(plot_data, aes(x = month, y = 100*fract, group=1)) +
  geom_line() +
  geom_point(aes(size=total)) +
  scale_size_continuous(guide=guide_legend(title="Number\nof Cases")) +
  scale_y_continuous(breaks=pretty_breaks(), limits=c(0,100), expand=c(0,0)) +
  labs(title = "Last Known Well Documented", x = "Time Point", y = "% of Cases Documented") 
plot_pointsize

# Make a line plot
plot <- ggplot(plot_data, aes(x = month, y = 100*fract, group=1)) +
  geom_line(size=2) +
  geom_point(size=2) +
  scale_y_continuous(breaks=pretty_breaks(), limits=c(0,100), expand=c(0,0)) +
  labs(title = "Last Known Well Documented", x = "Month", y = "% of Cases Documented") 
plot


# Make a table to go with it. Export csv or xlsx
outpath = file.path(here(), "last_known_well_summary.csv")
export_data <- plot_data %>%
  mutate(perc=fract*100) %>%
  rename(Month=month, "Documented Cases"=numer, "Total Cases"=total, "% Documented"=perc) %>%
  select(-fract) %>%
  write_csv(outpath)

