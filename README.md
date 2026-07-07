# epidemiology-dermoscopy-cancer
Interrupted Time Series (ITS) Analysis for Multiple Interventions

# Interrupted Time Series (ITS) Analysis for Multiple Interventions

This repository provides an R script for conducting an **Interrupted Time Series (ITS) analysis** to evaluate the impact of multiple sequential interventions (e.g., policy changes, infectious disease outbreaks, medical guidelines) on healthcare incidence rates.

## 📌 Key Features
- **Multiple Interventions:** Evaluates both level changes (immediate drop/spike) and trend changes (slope changes over time) across up to three distinct events.
- **Robust Statistics:** Uses **Newey-West robust standard errors** to correct for autocorrelation and heteroskedasticity, which are critical in time-series data.
- **Seasonality Adjustment:** Incorporates Fourier terms (sine and cosine with a 12-month period) to account for annual seasonal variations in the data.
- **Automatic Model Selection:** Fits 7 different Ordinary Least Squares (OLS) models (from a baseline counterfactual to a complex 3-intervention seasonality model) and selects the best fit using **AIC (Akaike Information Criterion)** and **BIC**.
- **Publication-Ready Visualization:** Automatically generates highly customized, annotated `ggplot2` trend plots (600 DPI) and exports statistical results to an Excel file.

## 📁 Data Preparation
Prepare your dataset as a monthly time-series CSV file (e.g., `your_dataset.csv`). 

### Required Columns:
- `YEAR` & `MONTH`: Time indicators (e.g., 2012, 1).
- `EVENT1_FLAG`, `EVENT2_FLAG`: Dummy variables (`0` for the months before the event, `1` starting from the month the event occurs). *Note: The start of Event 3 is automatically calculated as the month after Event 2 ends, but this can be customized.*
- `stdpop`: Standard population size, used as the denominator to calculate the incidence rate per 100,000 people.
- `Target_Variable_1`, etc.: The raw occurrence count of the condition you are analyzing.

### Sample Data Structure
| YEAR | MONTH | EVENT1_FLAG | EVENT2_FLAG | stdpop   | Target_Variable_1 |
| :--- | :---- | :---------- | :---------- | :------- | :---------------- |
| 2012 | 1     | 0           | 0           | 50000000 | 120               |
| ...  | ...   | ...         | ...         | ...      | ...               |
| 2020 | 3     | 1           | 1           | 51000000 | 90                |

## 🚀 How to Run
1. Open the R script in your environment (e.g., RStudio).
2. Install necessary packages if prompted (`tidyverse`, `lubridate`, `broom`, `sandwich`, `lmtest`, `writexl`).
3. Modify the `setwd_path` and `file_name` variables to point to your data file.
4. Execute the script. The script will export `.png` plots and `.xlsx` result tables to your directory.
