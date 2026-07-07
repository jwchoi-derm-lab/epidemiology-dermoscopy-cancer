# =========================================================
# 1. Load Required Packages
# =========================================================
# Run install.packages(c("tidyverse")) if you haven't installed them.
library(tidyverse)
library(grid) # Required for advanced annotation (linesGrob, arrow, unit)

# =========================================================
# 2. User Configuration (Adjust these to fit your data)
# =========================================================
# File Paths (Change these paths for your local environment)
input_file  <- "./data/your_dataset.csv"
output_file <- "./output/fig2_stacked_bar_plot.png"

# Study Period
start_year <- 2009
end_year   <- 2023

# Intervention Year (Where to split "Before" and "After")
# e.g., 2018.5 means exactly in the middle of 2018 and 2019
intervention_point <- 2018.5
label_before       <- "Before Intervention"
label_after        <- "After Intervention"

# --- Visual Adjustment Variables ---
# Arrow Y Position:
# Negative values move the arrow down below the x-axis. 
# Decrease the value (e.g., -0.45) to move the arrow further down.
arrow_y_position <- -0.35 

# Legend Margin Top:
# Increase this value (pt) to push the legend further down, 
# preventing overlap with the arrow and labels.
legend_margin_top <- 20

# Define Color Palette (Hex codes)
# Modify names and colors based on your actual variables.
color_palette <- c(
  "Category_1" = "#0047AB", # Solid Blue
  "Category_2" = "#7CA8D9", # Light Blue
  "Category_3" = "#B22222", # Solid Red
  "Category_4" = "#E68A8A"  # Light Red
)

# =========================================================
# 3. Data Loading & Preprocessing
# =========================================================
# Load data (Modify the data loading code according to your data structure)
df_raw <- read_csv(input_file, show_col_types = FALSE)

# Example Preprocessing (Replace this block with your actual grouping/summarising logic)
df_processed <- df_raw %>%
  filter(YEAR >= start_year & YEAR <= end_year) %>%
  group_by(YEAR) %>%
  summarise(
    V1_Male = sum(VAR1_M, na.rm = TRUE),
    V1_Female = sum(VAR1_F, na.rm = TRUE),
    V2_Male = sum(VAR2_M, na.rm = TRUE),
    V2_Female = sum(VAR2_F, na.rm = TRUE),
    V3_Male = sum(VAR3_M, na.rm = TRUE),
    V3_Female = sum(VAR3_F, na.rm = TRUE),
    V4_Male = sum(VAR4_M, na.rm = TRUE),
    V4_Female = sum(VAR4_F, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  # Pivot to long format for ggplot
  pivot_longer(
    cols = -YEAR,
    names_to = c("Variable", "Group"),
    names_pattern = "(V[1-4])_(Male|Female)",
    values_to = "Count"
  ) %>%
  mutate(
    Group = factor(Group, levels = c("Male", "Female"), labels = c("Men", "Women")),
    # Map raw variable names to the labels used in the color palette
    Variable = factor(
      Variable, 
      levels = c("V1", "V2", "V3", "V4"), 
      labels = c("Category_1", "Category_2", "Category_3", "Category_4")
    )
  )

# =========================================================
# 4. Calculate Data for Trend Line (Boundary Line)
# =========================================================
# Calculates the proportion of specific categories (e.g., Category 1 and 2) out of the total
df_line <- df_processed %>%
  group_by(YEAR, Group) %>%
  summarise(
    Total = sum(Count),
    Target_Sum = sum(Count[Variable %in% c("Category_1", "Category_2")]),
    Boundary_Ratio = Target_Sum / Total,
    .groups = "drop"
  )

# =========================================================
# 5. Position Calculations for Bottom Arrows & Ticks
# =========================================================
# We attach the arrow to the bottom facet (e.g., "Women")
bottom_facet <- data.frame(Group = factor("Women", levels = c("Men", "Women")))

left_margin  <- start_year - 0.35
right_margin <- end_year + 0.35

# Set coordinates for ticks at the ends of the arrows
y_arrow    <- arrow_y_position       
y_tick_top <- y_arrow + 0.03   
y_tick_bot <- y_arrow - 0.03   

# =========================================================
# 6. Create the Plot
# =========================================================
p <- ggplot() +
  # --- 100% Stacked Bar Plot ---
  geom_col(data = df_processed, aes(x = YEAR, y = Count, fill = Variable), 
           position = "fill", width = 0.7) +
  
  # --- Trend Line Graph ---
  geom_line(data = df_line, aes(x = YEAR, y = Boundary_Ratio), 
            color = "black", linewidth = 1.5, linetype = "solid") +
  geom_point(data = df_line, aes(x = YEAR, y = Boundary_Ratio), 
             color = "black", size = 2) +
  
  # --- Bottom Intervention Arrows & Lines (Attached to bottom facet) ---
  # Vertical line extending down to the arrow
  geom_segment(data = bottom_facet, aes(x = intervention_point, xend = intervention_point, y = 0, yend = y_arrow), 
               color = "black", linewidth = 1.5) +
  
  # Vertical Ticks at edges and intervention point
  geom_segment(data = bottom_facet, aes(x = left_margin, xend = left_margin, y = y_tick_top, yend = y_tick_bot), color = "black", linewidth = 1) +
  geom_segment(data = bottom_facet, aes(x = intervention_point, xend = intervention_point, y = y_tick_top, yend = y_tick_bot), color = "black", linewidth = 1) +
  geom_segment(data = bottom_facet, aes(x = right_margin, xend = right_margin, y = y_tick_top, yend = y_tick_bot), color = "black", linewidth = 1) +
  
  # Bidirectional Arrows
  geom_segment(data = bottom_facet, aes(x = left_margin, xend = intervention_point, y = y_arrow, yend = y_arrow), 
               arrow = arrow(length = unit(0.08, "inches"), ends = "both"), color = "black", linewidth = 0.8) +
  geom_segment(data = bottom_facet, aes(x = intervention_point, xend = right_margin, y = y_arrow, yend = y_arrow), 
               arrow = arrow(length = unit(0.08, "inches"), ends = "both"), color = "black", linewidth = 0.8) +
  
  # Text Labels inside the arrows
  geom_label(data = bottom_facet, aes(x = (left_margin + intervention_point)/2, y = y_arrow, label = label_before), 
             size = 4.5, fontface = "bold", fill = "white", label.size = 0, label.padding = unit(0.2, "lines")) +
  geom_label(data = bottom_facet, aes(x = (intervention_point + right_margin)/2, y = y_arrow, label = label_after), 
             size = 4.5, fontface = "bold", fill = "white", label.size = 0, label.padding = unit(0.2, "lines")) +
  
  # --- Aesthetics & Formatting ---
  scale_fill_manual(
    values = color_palette,
    breaks = c("Category_1", "Category_2", "Category_3", "Category_4")
  ) +
  
  # Split the plot by group vertically
  facet_wrap(~ Group, ncol = 1) +  
  
  # Prevent elements drawn outside the axis limits from being cut off
  coord_cartesian(clip = "off", ylim = c(0, 1)) +
  
  # Y-axis percentage format and continuous X-axis breaks
  scale_y_continuous(labels = scales::percent_format(), expand = c(0, 0)) +
  scale_x_continuous(breaks = seq(start_year, end_year, by = 1)) +
  
  labs(x = NULL, y = NULL) +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank(), 
    axis.line = element_line(color = "black", linewidth = 0.5), 
    axis.ticks = element_line(color = "black", linewidth = 0.5), 
    axis.ticks.length = unit(0.2, "cm"), 
    
    # Legend settings
    legend.position = "bottom",
    legend.direction = "horizontal",
    legend.title = element_blank(),
    legend.text = element_text(size = 14), 
    legend.margin = margin(t = legend_margin_top), 
    
    strip.text = element_text(size = 18, face = "bold"), 
    axis.title.x = element_blank(), 
    axis.title.y = element_blank(), 
    
    # Axis text settings (X-axis rotated 90 degrees)
    axis.text.x = element_text(size = 12, angle = 90, vjust = 0.5, hjust = 1, margin = margin(t = 5)),
    axis.text.y = element_text(size = 14, face = "bold", margin = margin(r = 5)),
    
    # Plot margins (Bottom margin scales dynamically with arrow_y_position to prevent cutoff)
    plot.margin = margin(t = 20, r = 20, b = max(110, abs(arrow_y_position)*200 + legend_margin_top), l = 20)
  ) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE)) +
  
  # Extend the vertical intervention line down from the top facet to the bottom arrow
  annotation_custom(
    grob = linesGrob(gp = gpar(col = "black", lwd = 2.5)), 
    xmin = intervention_point, xmax = intervention_point, 
    ymin = y_arrow, ymax = 1 
  )

# =========================================================
# 7. Save the Plot
# =========================================================
# Ensure the output directory exists
if(!dir.exists(dirname(output_file))) { dir.create(dirname(output_file), recursive = TRUE) }

ggsave(output_file, 
       plot = p, 
       width = 8, 
       height = 8, 
       dpi = 1200, 
       bg = "white")

cat("Complete! Plot saved to:", output_file, "\n")
