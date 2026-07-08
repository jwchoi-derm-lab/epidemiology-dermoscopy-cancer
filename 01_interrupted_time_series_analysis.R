# =========================================================
# 1. Load Required Packages
# =========================================================
# Install packages if you don't have them: 
# install.packages(c("tidyverse", "lubridate", "broom", "sandwich", "lmtest", "writexl"))
library(tidyverse)
library(lubridate)
library(broom)
library(sandwich) # For robust standard errors (Newey-West)
library(lmtest)   # For testing linear regression models
library(writexl)  # For exporting results to Excel

# =========================================================
# 2. Visual Configuration & Plot Settings
# =========================================================
# Adjust these variables to fine-tune the aesthetics of the output plot
label_y_pos    <- 4.2   # Y-axis position for event labels at the top
label_x_offset <- 2     # Margin offset (in months) for 'Study Start/End' labels
y_max_fixed    <- 4.5   # Fixed maximum value for the Y-axis to maintain consistency across plots
tick_y_end     <- 0.15  # Height of the custom tick marks on the X-axis
vline_alpha    <- 0.4   # Transparency level for the vertical dashed lines indicating events

# =========================================================
# 3. Data Loading & Preprocessing
# =========================================================
# TODO: Define your working directory path and dataset file name
setwd_path <- "path/to/your/data_directory/" 
file_name  <- "your_dataset.csv"

# Read the CSV file
df_raw <- read_csv(paste0(setwd_path, file_name), show_col_types = FALSE)

# TODO: Define the study period (Start and End year)
filter_start_year <- 2012
filter_end_year   <- 2023

# Standardize date format and filter by study period
df_raw <- df_raw %>%
  # TODO: Rename columns to match your dataset's event dummy variables
  rename(event1_flag = EVENT1_COLUMN_NAME, event2_flag = EVENT2_COLUMN_NAME) %>%
  mutate(date = make_date(YEAR, MONTH, 1)) %>%
  arrange(date) %>%
  filter(YEAR >= filter_start_year & YEAR <= filter_end_year) 

# =========================================================
# 4. Define Event Dates & X-Axis Custom Breaks
# =========================================================
study_start <- min(df_raw$date)
study_end   <- max(df_raw$date)

# Automatically identify the exact start date of each intervention based on flags
event1_start <- df_raw %>% filter(event1_flag == 1) %>% pull(date) %>% min()
event2_start <- df_raw %>% filter(event2_flag == 1) %>% pull(date) %>% min()
# Event 3 is assumed to start immediately after the Event 2 period ends
event3_start <- df_raw %>% filter(event2_flag == 1) %>% pull(date) %>% max() %m+% months(1)

# Set up breaks and labels for the X-axis
event_breaks <- c(study_start, event1_start, event2_start, event3_start, study_end)
event_labels <- paste0(year(event_breaks), ".", month(event_breaks), ".")

year_breaks <- seq(as.Date(paste0(filter_start_year, "-07-01")), as.Date(paste0(filter_end_year, "-07-01")), by = "year")
year_labels <- paste0("\n", format(year_breaks, "%Y"))

all_breaks <- c(event_breaks, year_breaks)
all_labels <- c(event_labels, year_labels)

# =========================================================
# 5. Feature Engineering for ITS Modeling
# =========================================================
# Create time components necessary for Interrupted Time Series Analysis
df_feat <- df_raw %>%
  mutate(
    Intercept = 1, 
    time = as.numeric(interval(study_start, date) %/% months(1)), # Continuous time from study start
    
    # Event 1: Trend change (time elapsed since Event 1 started)
    time_after_event1 = if_else(date >= event1_start, as.numeric(interval(event1_start, date) %/% months(1)), 0),
    
    # Event 2: Level shift (0 or 1) and Trend change
    event2_shift = if_else(date >= event2_start, 1, 0),
    time_after_event2 = if_else(date >= event2_start, as.numeric(interval(event2_start, date) %/% months(1)), 0),
    
    # Event 3: Level shift (0 or 1) and Trend change
    event3_shift = if_else(date >= event3_start, 1, 0),
    time_after_event3 = if_else(date >= event3_start, as.numeric(interval(event3_start, date) %/% months(1)), 0),
    
    # Seasonality parameters (Fourier terms for a 12-month annual cycle)
    sin12 = sin(2 * pi * time / 12),
    cos12 = cos(2 * pi * time / 12)
  )

# =========================================================
# 6. Helper Functions
# =========================================================
# Calculates predictions and 95% Confidence Intervals using Newey-West standard errors
get_custom_pred <- function(model, new_data, prefix) {
  Terms <- delete.response(terms(model))
  X <- model.matrix(Terms, model.frame(Terms, new_data, xlev = model$xlevels))
  V <- NeweyWest(model) # Robust covariance matrix
  beta <- coef(model)
  
  fit <- as.numeric(X %*% beta)
  se_fit <- sqrt(rowSums((X %*% V) * X))
  
  # Calculate lower and upper bounds for 95% CI
  lwr <- fit - 1.96 * se_fit
  upr <- fit + 1.96 * se_fit
  
  res <- tibble(fit = fit, lwr = lwr, upr = upr) %>% rename_with(~paste0(prefix, "_", .))
  return(res)
}

# =========================================================
# 7. Main Analysis & Plotting Function
# =========================================================
run_its_analysis <- function(target_var, stdpop_var = "stdpop") {
  
  # Calculate incidence rate per 100,000 population
  df <- df_feat %>% mutate(rate_100k = (.data[[target_var]] / .data[[stdpop_var]]) * 100000)
  
  # --- 7.1 Model Fitting (Unconstrained OLS) ---
  # M1: Baseline linear trend without any interventions
  m1 <- lm(rate_100k ~ 0 + Intercept + time, data = df)
  # M2-M4: Models incorporating sequential interventions
  m2 <- lm(rate_100k ~ 0 + Intercept + time + time_after_event1, data = df)
  m3 <- lm(rate_100k ~ 0 + Intercept + time + time_after_event1 + event2_shift + time_after_event2, data = df)
  m4 <- lm(rate_100k ~ 0 + Intercept + time + time_after_event1 + event2_shift + time_after_event2 + event3_shift + time_after_event3, data = df)
  
  # M5-M7: Models incorporating interventions AND seasonality adjustments
  m5 <- lm(rate_100k ~ 0 + Intercept + time + time_after_event1 + sin12 + cos12, data = df)
  m6 <- lm(rate_100k ~ 0 + Intercept + time + time_after_event1 + event2_shift + time_after_event2 + sin12 + cos12, data = df)
  m7 <- lm(rate_100k ~ 0 + Intercept + time + time_after_event1 + event2_shift + time_after_event2 + event3_shift + time_after_event3 + sin12 + cos12, data = df)
  
  # --- 7.2 Fitness Evaluation (AIC / BIC) ---
  fit_stats <- tibble(
    Model = c("M1: Baseline Trend", "M2: Event1 Only", "M3: Event1 + Event2", 
              "M4: Event1 + Event2 + Event3", "M5: M2 + Seasonality", 
              "M6: M3 + Seasonality", "M7: M4 + Seasonality"),
    AIC = c(AIC(m1), AIC(m2), AIC(m3), AIC(m4), AIC(m5), AIC(m6), AIC(m7)),
    BIC = c(BIC(m1), BIC(m2), BIC(m3), BIC(m4), BIC(m5), BIC(m6), BIC(m7))
  ) %>% arrange(AIC) # Lower AIC is better
  
  best_model <- fit_stats$Model[1]
  best_season_model <- fit_stats %>% 
    filter(Model %in% c("M5: M2 + Seasonality", "M6: M3 + Seasonality", "M7: M4 + Seasonality")) %>% 
    slice(1) %>% pull(Model)
  
  # Print evaluation results to the console
  cat("\n======================================================\n")
  cat(sprintf("Model Fit Summary for Variable: %s\n", target_var))
  cat("======================================================\n")
  print(fit_stats)
  cat("\n=> Best Overall Model (Lowest AIC):", best_model, "\n")
  cat("=> Selected Seasonality Model for Visualization:", best_season_model, "\n")
  cat("======================================================\n\n")
  
  # Generate robust standard errors for the final Excel report
  tidy_robust <- function(model, name) { tidy(coeftest(model, vcov = NeweyWest(model))) %>% mutate(Model = name) }
  res_all <- bind_rows(
    tidy_robust(m1, "M1: Baseline Trend"), tidy_robust(m2, "M2: Event1 Only"), 
    tidy_robust(m3, "M3: Event1 + Event2"), tidy_robust(m4, "M4: Event1 + Event2 + Event3"), 
    tidy_robust(m5, "M5: M2 + Seasonality"), tidy_robust(m6, "M6: M3 + Seasonality"), tidy_robust(m7, "M7: M4 + Seasonality")
  )
  
  # --- 7.3 Calculate Predictions for Plotting ---
  df <- bind_cols(
    df,
    get_custom_pred(m1, df, "m1"), get_custom_pred(m2, df, "m2"), get_custom_pred(m3, df, "m3"), get_custom_pred(m4, df, "m4"),
    get_custom_pred(m5, df, "m5"), get_custom_pred(m6, df, "m6"), get_custom_pred(m7, df, "m7")
  )
  
  plot_start_date <- as.Date(paste0(filter_start_year, "-01-01"))
  plot_end_date   <- as.Date(paste0(filter_end_year + 1, "-01-01"))
  
  # --- 7.4 Visualization (`ggplot2`) ---
  p <- ggplot(df, aes(x = date)) +
    # Background shading to distinguish intervention phases
    annotate("rect", xmin = event1_start, xmax = event2_start, ymin = 0, ymax = y_max_fixed, fill = "gray80", alpha = 0.3) +
    annotate("rect", xmin = event2_start, xmax = event3_start, ymin = 0, ymax = y_max_fixed, fill = "gray60", alpha = 0.3) +
    annotate("rect", xmin = event3_start, xmax = study_end,    ymin = 0, ymax = y_max_fixed, fill = "gray40", alpha = 0.3) +
    
    # Yearly vertical reference lines
    geom_vline(xintercept = seq(plot_start_date, plot_end_date, by = "year"), color = "gray88", linewidth = 0.4) +
    
    # Dashed lines for major events
    geom_vline(xintercept = study_start, linetype = "dashed", color = "black", linewidth = 0.8) +
    geom_vline(xintercept = study_end, linetype = "dashed", color = "black", linewidth = 0.8) +
    geom_vline(xintercept = event1_start, linetype = "dashed", color = "purple", linewidth = 0.8, alpha = vline_alpha) +
    geom_vline(xintercept = event2_start, linetype = "dashed", color = "darkgreen", linewidth = 0.8, alpha = vline_alpha) +
    geom_vline(xintercept = event3_start, linetype = "dashed", color = "darkred", linewidth = 0.8, alpha = vline_alpha) +
    
    # Custom ticks on the X-axis for precise event mapping
    annotate("segment", x = event_breaks, xend = event_breaks, y = 0, yend = tick_y_end, linewidth = 1.5, color = "black") +
    
    # Text labels and arrows for interventions at the top of the plot
    annotate("text", x = study_start %m+% months(label_x_offset), y = label_y_pos, label = "Study Start", hjust = 0, color = "black") +
    annotate("text", x = study_end %m-% months(label_x_offset), y = label_y_pos, label = "Study End", hjust = 1, color = "black") +
    
    annotate("text", x = event1_start %m-% months(2), y = label_y_pos, label = "Event 1", hjust = 1, vjust = 0.5, color = "purple") +
    annotate("segment", x = event1_start %m-% months(2), xend = event1_start, y = label_y_pos, yend = label_y_pos, arrow = arrow(length = unit(0.2, "cm")), color = "purple") +
    
    annotate("text", x = event2_start %m-% months(2), y = label_y_pos, label = "Event 2", hjust = 1, vjust = 0.5, color = "darkgreen") +
    annotate("segment", x = event2_start %m-% months(2), xend = event2_start, y = label_y_pos, yend = label_y_pos, arrow = arrow(length = unit(0.2, "cm")), color = "darkgreen") +
    
    annotate("text", x = event3_start %m-% months(2), y = label_y_pos, label = "Event 3", hjust = 1, vjust = 0.5, color = "darkred") +
    annotate("segment", x = event3_start %m-% months(2), xend = event3_start, y = label_y_pos, yend = label_y_pos, arrow = arrow(length = unit(0.2, "cm")), color = "darkred") +
    
    # Draw trend lines (fitted values) and ribbons (95% Confidence Intervals)
    geom_ribbon(aes(ymin = m1_lwr, ymax = m1_upr), fill = "gray40", alpha = 0.05) +
    geom_line(aes(y = m1_fit, color = "M1: Baseline Trend"), linetype = "dashed", linewidth = 0.8) +
    
    geom_ribbon(aes(ymin = m2_lwr, ymax = m2_upr), fill = "purple", alpha = 0.05) +
    geom_line(aes(y = m2_fit, color = "M2: Event1 Only"), linewidth = 1.0) +
    
    geom_ribbon(aes(ymin = m3_lwr, ymax = m3_upr), fill = "green",  alpha = 0.05) +
    geom_line(aes(y = m3_fit, color = "M3: Event1 + Event2"), linewidth = 1.0) +
    
    geom_ribbon(aes(ymin = m4_lwr, ymax = m4_upr), fill = "red",    alpha = 0.05) +
    geom_line(aes(y = m4_fit, color = "M4: Event1 + Event2 + Event3"), linewidth = 1.0) +
    
    # Scatter points representing the actual data
    geom_point(aes(y = rate_100k), shape = 1, color = "gray50", size = 1.2, stroke = 0.7, alpha = 0.3)
  
  # Dynamically add the best-fitting seasonality model to the plot
  if (best_season_model == "M5: M2 + Seasonality") {
    p <- p + geom_ribbon(aes(ymin = m5_lwr, ymax = m5_upr), fill = "blue", alpha = 0.05) + geom_line(aes(y = m5_fit, color = "M5: M2 + Seasonality"), linewidth = 0.8)
  } else if (best_season_model == "M6: M3 + Seasonality") {
    p <- p + geom_ribbon(aes(ymin = m6_lwr, ymax = m6_upr), fill = "orange", alpha = 0.05) + geom_line(aes(y = m6_fit, color = "M6: M3 + Seasonality"), linewidth = 0.8)
  } else if (best_season_model == "M7: M4 + Seasonality") {
    p <- p + geom_ribbon(aes(ymin = m7_lwr, ymax = m7_upr), fill = "brown", alpha = 0.05) + geom_line(aes(y = m7_fit, color = "M7: M4 + Seasonality"), linewidth = 0.8)
  }
  
  # Finalize aesthetics and theme
  p <- p +
    scale_color_manual(values = c(
      "M1: Baseline Trend" = "gray40", "M2: Event1 Only" = "purple",
      "M3: Event1 + Event2" = "green", "M4: Event1 + Event2 + Event3" = "red",
      "M5: M2 + Seasonality" = "blue", "M6: M3 + Seasonality" = "orange", "M7: M4 + Seasonality" = "brown"
    )) +
    scale_x_date(breaks = all_breaks, labels = all_labels, expand = c(0.01, 0)) +
    scale_y_continuous(limits = c(0, y_max_fixed), expand = c(0, 0)) +
    coord_cartesian(ylim = c(0, y_max_fixed), clip = "off") +
    theme_classic() +
    labs(
      title = paste("Interrupted Time Series Analysis:", target_var),
      subtitle = "Trend Comparison Across Intervention Phases",
      x = "Year Interval", y = "Incidence Rate (per 100,000)", color = NULL
    ) +
    theme(
      legend.position = "bottom",
      axis.ticks.x = element_blank(),
      axis.text.x = element_text(vjust = 1, size = 10, color = "black", margin = margin(t = 5)), 
      plot.margin = margin(t = 10, r = 10, b = 10, l = 10) 
    )
  
  print(p)
  
  # --- 7.5 Export Results ---
  # Save the plot as a high-resolution PNG
  ggsave(paste0(setwd_path, "ITS_TrendPlot_", target_var, ".png"), plot = p, width = 10, height = 7, dpi = 600)
  
  # Save statistical metrics and coefficients to Excel
  interp_df <- tibble(
    Interpretation = c(
      "AIC and BIC evaluate model fit while penalizing for complexity.",
      "Lower values signify a mathematically superior model.",
      sprintf("Best Overall Model for %s: %s", target_var, best_model),
      sprintf("Selected Seasonality Model for plotting: %s", best_season_model)
    )
  )
  
  write_xlsx(
    list(Fitness_Metrics = fit_stats, Interpretation = interp_df, Robust_Coefficients = res_all),
    paste0(setwd_path, "ITS_Model_Results_", target_var, ".xlsx")
  )
}

# =========================================================
# 8. Execute Analysis
# =========================================================
# TODO: Call the function with the names of your target columns
# run_its_analysis("Target_Variable_1")
# run_its_analysis("Target_Variable_2") 
