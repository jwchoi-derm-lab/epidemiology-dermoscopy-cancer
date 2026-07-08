# 🩺 Impact of Dermoscopy Reimbursement on Skin Cancer Incidence

![R](https://img.shields.io/badge/R-4.0%2B-276DC3?logo=r&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Status](https://img.shields.io/badge/Status-Active-brightgreen)

A statistical codebase evaluating the impact of national **dermoscopy reimbursement** and the **COVID-19 pandemic** on skin cancer incidence rates. This repository provides a fully reproducible workflow — from synthetic data generation to Interrupted Time Series (ITS) modeling and publication-ready visualizations.

> 📢 **Note:** This repository accompanies a manuscript currently under peer review. In accordance with the journal's Data Availability Statement, this repository will be made publicly accessible upon publication of the article.

---

## 📖 Table of Contents
- [Clinical Context](#-clinical-context--codes)
- [Repository Structure](#-repository-structure)
- [Getting Started](#-getting-started)
- [Data Availability](#-data-availability)
- [License](#-license)

---

## 🔬 Clinical Context & Codes

This codebase was originally developed to analyze the **Korean National Health Insurance Service (NHIS)** sample cohort database.

| Category | Detail |
| :--- | :--- |
| **Intervention** | National insurance coverage for dermoscopy (procedure code: `E6614%`), introduced **March 2019** |
| **Melanoma** | ICD-10 `C43` |
| **Non-melanoma skin cancer** | ICD-10 `C44` |
| **Melanoma in situ** | ICD-10 `D03` |
| **Carcinoma in situ** | ICD-10 `D04` |

> **Note:** In the Korean NHIS database, biopsy-confirmed malignant cases are strictly defined by combining the ICD-10 codes above with specific special coverage codes (`V027`, `V192`, `V193`).

---

## 📁 Repository Structure

### `00_generate_sample_data.R` — Synthetic Data Generator
Due to strict privacy policies of the NHIS, raw patient-level data and aggregate pivot tables cannot be exported outside the secure server. This script generates a synthetic dataset so external researchers can reproduce and test the workflow.

- **Simulates:** 180 months (Jan 2009 – Dec 2023) of realistic time-series data using Poisson distributions (`rpois`).
- **Reflects:** Baseline trends and incidence shifts following Event 1 (Dermoscopy) and Event 2 (COVID-19).
- **Output:** `./data/your_dataset.csv`

### `01_interrupted_time_series_analysis.R` — ITS Modeling & Trend Visualization
Automates fitting, comparing, and visualizing multiple ITS regression models to quantify the sequential impact of interventions.

- **Statistical approach:** Ordinary Least Squares (OLS) regression with **Newey-West robust standard errors** to correct for autocorrelation and heteroskedasticity, plus Fourier terms (`sin12`, `cos12`) for seasonality adjustment.
- **Model selection:** Evaluates 7 candidate models — from a baseline trend to a full 3-event seasonality model — and automatically selects the best fit via **AIC/BIC**.
- **Output:** A publication-ready `ggplot2` trend plot (`.png`) and an Excel report (`.xlsx`) with robust coefficients and fitness metrics, saved to `./output/`.

### `02_stacked_bar_trend_plot.R` — Incidence Composition Plot
Generates a 100% stacked bar plot showing the annual composition of diagnostic categories, split by subgroup (e.g., sex).

- **Features:** Stacked bars combined with a trend line tracking the proportion of early-stage diagnoses (e.g., *in situ* lesions).
- **Custom annotations:** A fully adjustable bidirectional arrow marks the "Before" and "After" intervention periods — tune `arrow_y_position` and `legend_margin_top` to prevent overlap.
- **Output:** `./output/fig2_stacked_bar_plot.png`

---

## 🚀 Getting Started

1. **Clone** this repository:
   ```bash
   git clone https://github.com/jwchoi-derm-lab/epidemiology-dermoscopy-cancer.git
   ```
2. **Install** required R packages:
   ```r
   install.packages(c("tidyverse", "lubridate", "broom", "sandwich", "lmtest", "writexl", "grid"))
   ```
3. **Generate** the sample dataset:
   ```r
   source("R/00_generate_sample_data.R")
   ```
4. **Run** the analysis and visualization scripts:
   ```r
   source("R/01_interrupted_time_series_analysis.R")
   source("R/02_stacked_bar_trend_plot.R")
   ```

---

## 📊 Data Availability

The analytic code used in this study is openly available in this GitHub repository ([https://github.com/jwchoi-derm-lab/epidemiology-dermoscopy-cancer](https://github.com/jwchoi-derm-lab/epidemiology-dermoscopy-cancer)) and will be accessible to the public from the date of publication onward. Prior to publication, the code is available from the corresponding author upon reasonable request from editors or reviewers.

Due to data protection regulations of the Korean National Health Insurance Service (NHIS), the underlying patient-level dataset used in this study cannot be shared publicly. A synthetic sample dataset (`00_generate_sample_data.R`) is provided instead to allow full reproducibility of the analytic workflow.

---

## 📝 License
This project is open-source and available under the [MIT License](https://github.com/jwchoi-derm-lab/epidemiology-dermoscopy-cancer/blob/main/LICENSE).
