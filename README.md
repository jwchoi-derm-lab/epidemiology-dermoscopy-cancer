# Impact of Dermoscopy Reimbursement on Skin Cancer Incidence: Statistical Codebase

![GitHub repo size](https://img.shields.io/github/repo-size/jwchoi-derm-lab/epidemiology-dermoscopy-cancer
) 
![GitHub last commit](https://img.shields.io/github/last-commit/jwchoi-derm-lab/epidemiology-dermoscopy-cancer
)
![GitHub issues](https://img.shields.io/github/issues/jwchoi-derm-lab/epidemiology-dermoscopy-cancer
)
---

This repository contains the R scripts used to evaluate the impact of national **dermoscopy reimbursement** and the **COVID-19 pandemic** on the incidence rates of skin cancers. It provides a workflow including dummy data generation, Interrupted Time Series (ITS) modeling, and visualizations.

## 🔬 Clinical Context & Codes

The codes in this repository were originally developed to analyze the Korean National Health Insurance Service (NHIS) sample cohort data.

*   **Intervention (Dermoscopy):** National health insurance coverage for dermoscopy (procedure code: `E6614%`) was introduced in **March 2019**.
*   **Target Outcomes (Skin Cancer & In Situ):** 
    *   Melanoma (`C43`)
    *   Non-melanoma skin cancer (`C44`)
    *   Melanoma in situ (`D03`)
    *   Carcinoma in situ (`D04`)
*   *Note: In Korean NHIS data, biopsy confirmed malignant cases are strictly defined by combining the ICD-10 codes above with specific special coverage codes (`V027`, `V192`, `V193`).*

---

## 📁 Repository Structure & Usage

### 1. Generating Sample Data (`0_create_sample_data.R`)
To test the analysis codes without actual patient data, run this script first.
*   **Why it's needed:** Due to the strict privacy policies of the Korean National Health Insurance Service (NHIS), raw patient-level data and aggregate pivot tables cannot be exported out of the secure server. Therefore, this script generates synthetic data to provide a reproducible environment for outside researchers to test the code.
*   **What it does:** Simulates 180 months (Jan 2009 - Dec 2023) of realistic time-series data using Poisson distributions (`rpois`). It automatically reflects baseline trends and incidence shifts following Event 1 (Dermoscopy) and Event 2 (COVID-19).
*   **Output:** Generates a synthetic dataset at `./data/your_dataset.csv`.

### 2. Interrupted Time Series (ITS) Analysis (`1_its_analysis_trend_visualization.R`)
This script automates the process of fitting, comparing, and visualizing multiple ITS regression models to evaluate the sequential impact of interventions.
*   **Statistical Approach:** Uses Ordinary Least Squares (OLS) regression with **Newey-West robust standard errors** to correct for autocorrelation and heteroskedasticity. Incorporates Fourier terms (`sin12`, `cos12`) to adjust for annual seasonality.
*   **Model Selection:** Evaluates 7 different models (from baseline trend to complex 3-event seasonality models) and automatically selects the best fit using **AIC/BIC**.
*   **Output:** Generates a highly customized `ggplot2` trend plot (`.png`) and an Excel report (`.xlsx`) containing robust coefficients and fitness metrics in the `./output/` directory.

### 3. 100% Stacked Bar Plot with Trend Line (`2_skin_cancer_incidence_stacked_bar_plot.R`)
This script creates a publication-ready 100% stacked bar plot to show the proportion of multiple diagnostic categories across years, split by gender or other sub-groups.
*   **Features:** Displays stacked bars alongside a line graph calculating the proportion of early-stage targets (e.g., *in situ* lesions). 
*   **Custom Annotations:** Features a highly customizable bidirectional arrow at the bottom to visually split the "Before" and "After" periods of the intervention. You can adjust the `arrow_y_position` and `legend_margin_top` directly in the code to prevent overlap.
*   **Output:** Generates `fig2_stacked_bar_plot.png` in the `./output/` directory.

---

## 🚀 Getting Started

1. Clone this repository to your local environment.
2. Install required R packages: 
   ```R
   install.packages(c("tidyverse", "lubridate", "broom", "sandwich", "lmtest", "writexl", "grid"))
   ```
3. Run `0_create_sample_data.R` to build the required `./data/your_dataset.csv`.
4. Run `1_its_analysis.R` and `2_stacked_bar_plot.R` to generate plots and statistical tables.

## 📝 License
This project is open-source and available under the [MIT License](LICENSE).
