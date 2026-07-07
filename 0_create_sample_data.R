# =========================================================
# Generate Sample Dataset for GitHub Repository
# =========================================================
library(tidyverse)
library(lubridate)

# 1. Set time sequence (Jan 2009 to Dec 2023)
df_sample <- expand_grid(
  YEAR = 2009:2023,
  MONTH = 1:12
) %>%
  mutate(
    date = make_date(YEAR, MONTH, 1),
    
    # 2. Event Dummy Variables
    # Event 1 starts in July 2018 (Matches intervention_point = 2018.5)
    EVENT1_COLUMN_NAME = if_else(date >= as.Date("2018-07-01"), 1, 0),
    
    # Event 2 starts in March 2020 (e.g., COVID-19 outbreak)
    EVENT2_COLUMN_NAME = if_else(date >= as.Date("2020-03-01"), 1, 0),
    
    # 3. Standard Population (gradually increasing)
    stdpop = 50000000 + (YEAR - 2009) * 100000 + MONTH * 5000
  ) %>%
  
  # 4. Simulate target variables with baseline trends and event shifts
  mutate(
    # Create a baseline trend that increases over time
    base_rate = 100 + (YEAR - 2009) * 5, 
    # Add a 20% increase after Event 1, and a 30% decrease after Event 2
    rate_adj = base_rate * (1 + EVENT1_COLUMN_NAME * 0.2) * (1 - EVENT2_COLUMN_NAME * 0.3),
    
    # Variables for Code 1 (ITS Analysis)
    Target_Variable_1 = rpois(n(), rate_adj),
    Target_Variable_2 = rpois(n(), rate_adj * 0.5),
    
    # Variables for Code 2 (100% Stacked Bar Plot)
    VAR1_M = rpois(n(), rate_adj * 0.30),
    VAR1_F = rpois(n(), rate_adj * 0.32),
    VAR2_M = rpois(n(), rate_adj * 0.20),
    VAR2_F = rpois(n(), rate_adj * 0.18),
    VAR3_M = rpois(n(), rate_adj * 0.15),
    VAR3_F = rpois(n(), rate_adj * 0.16),
    VAR4_M = rpois(n(), rate_adj * 0.05),
    VAR4_F = rpois(n(), rate_adj * 0.04)
  ) %>%
  # Remove temporary calculation columns
  select(-date, -base_rate, -rate_adj)

# =========================================================
# Save to CSV
# =========================================================
# Create data folder if it doesn't exist
if(!dir.exists("./data")) { dir.create("./data") }

# Save the dataset
write_csv(df_sample, "./data/your_dataset.csv")

cat("Sample dataset successfully generated at ./data/your_dataset.csv")
