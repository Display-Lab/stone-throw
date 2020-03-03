library(dplyr)
library(readr)
library(tidyr)
library(stringr)

# Munge tpa case spreadsheet

# Read csv
in_file_path <- "./input/tPA_case_data.csv"
df_raw <- read_csv(in_file_path)

# Remove cols with default names
df2 <- df_raw %>% select(-matches("^X\\d"))

# De-multiplex Date of tPA column to: Month, Quarter, QCase
ensure_month_quarter_split <- function(x){ gsub("(\\w)Q","\\1 Q", x) }
df3 <- df2 %>%
  rename("mplex"="Date of tPA") %>% 
  mutate(mplex= ensure_month_quarter_split(mplex)) %>% 
  separate(col=mplex, into=c("month", "quarter", "case"), sep=" ", remove=TRUE) %>%
  mutate(quarter=gsub("Q","",quarter), month=match(month, month.abb) )
  
# remove '*' char
# trim leading & trailing spaces
# blanks to NA
# drop "Excluded from data" column
df4 <-df3 %>%
  mutate_all(.funs = function(x){gsub("\\*","",x)}) %>%
  mutate_all(.funs = str_trim) %>%
  mutate_all(.funs = function(x){replace(x, x == "N/A", NA)}) %>%
  select(-`Excluded from data`)

# Output as tpa_processed.csv
out_file_path<- "input/tPA_case_data_processed.csv"
write_csv(df4, out_file_path)

