# last known normal line plotting
library(tidyr)
library(ggplot2)
library(dplyr, warn.conflicts = FALSE)
library(here)
library(readr)
library(cowplot)

# Read raw data.

col_names <- c('grp','quarter',paste('bin',c(1:14),sep='_'), 'unk_1','unk_2','total', paste('stat',c(1:4), sep='_'))
# "grp"     "quarter" "bin_1"   "bin_2"   "bin_3"   "bin_4"  
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
  mutate(quarter=quarter + c(.1,.2,.3)) %>%
  mutate(quarter=as.factor(paste0('Q',quarter))) %>%
  mutate_at(vars(starts_with("bin_")), .funs=as.integer)

# Make plot data
# Sum the time bins as the numerator
# calculate the fraction of total cases with documented LKN
plot_data <- df1 %>% 
  group_by(quarter) %>%
  gather(key=time_bin, value=count, starts_with("bin_")) %>%
  group_by(quarter, total) %>% summarize(numer=sum(count)) %>%
  mutate(fract=numer/total)
  
# Make a line plot
plot <- ggplot(plot_data, aes(x = quarter, y = 100*fract, group=1)) +
  geom_line(size=2) +
  geom_point(size=3) +
  scale_y_continuous(breaks=pretty_breaks(), limits=c(0,100), expand=c(0,0)) +
  labs(title = "Last Known Normal Documented", x = "Time Point", y = "% of Cases Documented") 
plot


# Make a table to go with it. Export csv or xlsx
outpath = file.path(here(), "lkn.csv")
export_data <- plot_data %>%
  mutate(perc=fract*100) %>%
  rename(Quarter=quarter, "Documented Cases"=numer, "Total Cases"=total, "% Documented"=perc) %>%
  select(-fract) %>%
  write_csv(outpath)

