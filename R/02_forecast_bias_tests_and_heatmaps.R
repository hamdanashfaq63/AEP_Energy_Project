# Forecast bias tests and load heatmaps, PJM RTO
# Author: Daniel Ha (DA 301 team)
#
# Paired t-tests of actual vs. forecast load (overall and by forecast horizon),
# a chi-square test on categorized load, forecast bias by hour of day, and the
# weekly load heatmap. Inputs are described in data/README.md.

# July - October, 2025 t-test
library(tidyverse)
library(httr2)
library(lubridate)
library(ggplot2)
# -------------------------------------------------------------
# 1. READ RAW DATA
# -------------------------------------------------------------

# Read actual metered load dataset
actual_df1 <- read_csv("data/hour_load_metered.csv")
forecast_df1 <- read_csv("data/forecasted_hourly_transmission_load.csv")

# -------------------------------------------------------------
# 2. DATETIME PARSING
# -------------------------------------------------------------
# Read forecasted transmission load dataset
actual_df1 <- actual_df1 %>%
  mutate(datetime_beginning_ept = mdy_hms(datetime_beginning_ept))

# Convert forecast timestamps using YMD_HMS (e.g., "2025-10-15 08:00:00")
forecast_df1 <- forecast_df1 %>%
  mutate(forecast_datetime_beginning_ept = ymd_hms(forecast_datetime_beginning_ept))

# -------------------------------------------------------------
# 3. FILTER TO RTO REGION ONLY
# -------------------------------------------------------------
# Convert actual timestamps from character -> POSIXct (MDY_HMS format)
actual_df1_rto <- actual_df1 %>%
  filter(zone == "RTO")

# PJM forecast data uses "RTO_COMBINED"
forecast_df1_rto <- forecast_df1 %>%
  filter(forecast_area == "RTO_COMBINED") %>%
  mutate(forecast_area = "RTO")

# -------------------------------------------------------------
# 4. MERGE ACTUAL + FORECAST DATA
# -------------------------------------------------------------
# Perform an inner join:
#   - Match timestamps
#   - Match RTO region
#
# join keys:
#   actual_df1$datetime_beginning_ept  == forecast_df1_rto$forecast_datetime_beginning_ept
#   actual_df1$zone                    == forecast_df1_rto$forecast_area
#
# After merge:
#   mw                -> actual observed load (MW)
#   forecast_load_mw  -> forecasted load (MW)

merged_df1 <- actual_df1 %>%
  inner_join(forecast_df1_rto,
             by = c("datetime_beginning_ept" = "forecast_datetime_beginning_ept",
                    "zone" = "forecast_area")) %>%
  mutate(error = mw - forecast_load_mw)

# -------------------------------------------------------------
# 5. PAIRED t-TEST: ACTUAL vs FORECAST MW
# -------------------------------------------------------------

# Because each timestamp has:
#     - one actual MW value
#     - one forecast MW value
# July - October, 2025 t-test
t.test(merged_df1$mw, merged_df1$forecast_load_mw, paired = TRUE)


# -------------------------------------------------------------
# 6. CHI-SQUARE TEST: CATEGORIZED LOAD (LOW / MED / HIGH)
# -------------------------------------------------------------
#Chi-square test for RTO region
rto_df1 <- merged_df1 %>%
  mutate(
    actual_cat = cut(mw, breaks = 3, labels = c("Low", "Med", "High")),
    forecast_cat = cut(forecast_load_mw, breaks = 3, labels = c("Low", "Med", "High"))
  )
tbl <- table(rto_df1$actual_cat, rto_df1$forecast_cat)
chisq.test(tbl)


# -------------------------------------------------------------------------
# FORECAST ERROR VISUALIZATION
# Plot: Forecast Error Over Time (Actual - Forecast), July to October 2025
#
# Purpose:
#   This plot shows how the forecasting error evolves over the July to October
#   2025 period. The "error" variable should be defined as:
#         error = actual_mw - forecast_mw
#   Positive values -> Forecast UNDERpredicts demand.
#   Negative values -> Forecast OVERpredicts demand.
#
# Visualization choices:
#   - geom_line()    -> Shows high-frequency hour-by-hour variation.
#   - alpha = 0.4    -> Slight transparency reduces noise and visual clutter.
#   - geom_smooth()  -> LOESS curve highlights the overall trend in errors
#                      (e.g., seasonal drift, systematic bias).
#   - red smoothing line -> Makes long-term bias visually obvious.
# -------------------------------------------------------------------------
#Forecast Error Over Time(Actual - Forecast) July-October 2025
merged_df1 %>%
  ggplot(aes(x = datetime_beginning_ept, y = error)) +
 # Hourly error time-series line
  geom_line(alpha = 0.4) +
 # LOESS smoothing curve to reveal long-run pattern in prediction bias
  geom_smooth(color = "red", method = "loess") +
 # Axis labels & title
  labs(title="Forecast Error Over Time (Actual - Forecast) July-October 2025",
       y="MegaWatt Error", x ="Months")


# -------------------------------------------------------------------------
# FORECAST BIAS BY HOUR OF DAY (Actual - Forecast)
#
# Purpose:
#   Identify whether forecast errors follow a systematic hourly pattern.
#   PJM demand often has strong diurnal cycles, so forecasting models may
#   underpredict or overpredict during specific times of day.
#
#   error = actual_mw - forecasted_mw
#   Positive mean error  -> Underprediction (actual > forecast)
#   Negative mean error  -> Overprediction (actual < forecast)
#
# Steps:
#   1. Compute hourly error for each timestamp.
#   2. Extract hour-of-day from datetime.
#   3. Compute mean error per hour.
#   4. Plot mean error across 24 hours to visualize bias patterns.
# -------------------------------------------------------------------------
# Step 1: Create error column (Actual - Forecast)
rto_df1 <- rto_df1 %>%
  mutate(error = mw - forecast_load_mw)

# Step 2: Extract the "hour" component from the timestamp
# EPT = Eastern Prevailing Time (PJM standard)
rto_df1 <- rto_df1 %>%
  mutate(hour = lubridate::hour(datetime_beginning_ept))

# Step 3: Compute average forecast bias for each hour of the day
#   - group_by(hour): groups all timestamps by their hour (0-23)
hourly_bias <- rto_df1 %>%
  group_by(hour) %>%
  summarise(mean_error = mean(error), .groups = "drop")

# Print summary table (helpful for reporting and debugging)
hourly_bias


# -------------------------------------------------------------------------
# PLOT: Forecast Bias by Hour of Day
#
# Visualization choices:
#   - Line plot: hour-to-hour trend is easier to interpret as continuous cycle.
#   - Steelblue line: visually clear without overpowering the plot.
#   - Horizontal line at y = 0: separates underprediction vs. overprediction.
#
# Interpretation:
#   - Points above the zero line -> Model underpredicts load.
#   - Points below the zero line -> Model overpredicts load.
#   - Consistent patterns suggest structural bias (e.g., evening ramp).
# -------------------------------------------------------------------------

ggplot(hourly_bias, aes(x = hour, y = mean_error)) +
  geom_line(color = "steelblue", size = 1.1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Forecast Bias by Hour of Day (Actual - Forecast)",
    x = "Hour of Day (EPT)",
    y = "Mean Error (MW)"
  ) +
  theme_minimal()


# -------------------------------------------------------------------
# WEEKLY ELECTRICITY LOAD HEATMAP (RTO, Full Year 2024)
#
# Goal:
#   Visualize how average load (MW) varies by:
#     - Day of week (x-axis)
#     - Hour of day (y-axis)
#   for the RTO zone over the full 2024 year.
#
#   Uses a heatmap to show typical weekly pattern (weekday/weekend,
#   daytime vs nighttime, peak hours, etc.).
# -------------------------------------------------------------------
#HEATMAP for entire year of 2024
library(tidyverse)
library(lubridate)
library(viridis)
library(forcats)

# -------------------------------------------------------------------
# 1) READ DATA
# -------------------------------------------------------------------
df <- read_csv("data/actual_Load.csv")
                      
# -------------------------------------------------------------------
# 2) PARSE TIME & DERIVE TIME FEATURES
# -------------------------------------------------------------------
# ---- 2) parse time & derive features ----
df <- df %>%
  mutate(
    # parse_date_time tries multiple formats in order:
    datetime = parse_date_time(datetime_beginning_ept,
                               orders = c("mdy HMS", "mdY IMS p")),
     # Extract just the date part (no time component)
    date = as_date(datetime),
    # Hour of day as integer 0-23 (based on parsed datetime)
    hour = hour(datetime),
    wday = wday(datetime, label = TRUE, abbr = FALSE, week_start = 1)
    # Monday = 1, labels "Monday","Tuesday",...,"Sunday"
  )

# -------------------------------------------------------------------
# 3) FILTER TO RTO ZONE
# -------------------------------------------------------------------
# Keep only RTO zone rows and keep just columns needed for heatmap.
# Also remove any rows with missing MW values.
#3) filter to RTO zone
rto <- df %>%
  filter(zone == "RTO") %>%
  select(wday, hour, mw) %>%
  filter(!is.na(mw))

# -------------------------------------------------------------------
# 4) AVERAGE LOAD BY WEEKDAY x HOUR
# -------------------------------------------------------------------
#4) average load by weekday & hour
heat <- rto %>%
  group_by(wday, hour) %>%
  summarise(avg_mw = mean(mw, na.rm = TRUE), .groups = "drop")


# -------------------------------------------------------------------
# 5) HEATMAP PLOT
# -------------------------------------------------------------------

# Create a heatmap:
#   - x-axis   -> Weekday (Monday to Sunday)
#   - y-axis   -> Hour of day (0-23); reversed so midnight is at bottom
#   - fill     -> Average MW (color intensit
#5) heatmap
p <- ggplot(heat, aes(x = wday, y = hour, fill = avg_mw)) +
  geom_tile(color = "white", linewidth = 0.2) +
  scale_y_reverse(breaks = seq(0, 23, 3), expand = c(0, 0)) +
  scale_fill_viridis(option = "C", name = "Avg Load (MW)") +
  labs(
    title = "Weekly Electricity Load Pattern (Full year 2024)",
    subtitle = "Average MegaWatt load",
    y = "Hour of Day",
    x = NULL,
    caption = "Source: PJM actual_Load dataset; cells show mean hourly MW (RTO Zone)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16, margin = margin(b = 6)),
    plot.subtitle = element_text(margin = margin(b = 10)),
    panel.grid = element_blank(),
    legend.position = "right",
    plot.background = element_rect(fill = "#faf9f6", color = NA),
    panel.background = element_rect(fill = "#faf9f6", color = NA)
  ) + theme(plot.background = element_rect(fill = "#F2F2F2", color = NA))

print(p)
ggsave("heatmap_RTO_weekly_pattern.png", p, width = 10, height = 7, dpi = 300)


# -------------------------------------------------------------------------
# Paired t-tests for Forecast Accuracy at 24-32 hr and 40-48 hr Horizons
#
# Goal:
#   Evaluate forecast bias at two forecast horizons by comparing
#   actual vs. forecasted RTO load at matched timestamps.
#
# Method:
#   - Convert timestamps
#   - Filter to RTO zone only
#   - Compute forecast horizons (difference between forecast time and evaluation time)
#   - Extract only forecasts within two windows: 24-32 hr and 40-48 hr
#   - Join forecast and actual loads by timestamp
#   - Run paired t-tests for each window
#
# Interpretation of the paired t-test:
#   H0: mean(actual - forecast) = 0   -> No systematic bias
#   H1: mean(actual - forecast) != 0   -> Forecasts are biased (over/under)
#
# -------------------------------------------------------------------------
#Paired t-test (24-32 hour interval)  (40-48hour interval)!
library(tidyverse)
library(lubridate)
library(viridis)
library(forcats)

# -------------------------------------------------------------------------
# 1. LOAD RAW DATA
# -------------------------------------------------------------------------
actual_df <- read_csv("data/hour_load_metered.csv", show_col_types = FALSE)
forecast_df <- read_csv("data/forecasted_hourly_transmission_load.csv", show_col_types = FALSE)

# -------------------------------------------------------------------------
# 2. PARSE TIMESTAMPS SAFELY
# -------------------------------------------------------------------------
# Actual load time uses mdy_hms format such as "10/14/2025 08:00:00"
actual_df <- actual_df %>%
  mutate(datetime_beginning_ept = mdy_hms(datetime_beginning_ept, quiet = TRUE))

# Forecast evaluation timestamp uses ymd_hms format
forecast_df <- forecast_df %>%
  mutate(evaluated_at_datetime_ept = ymd_hms(evaluated_at_datetime_ept, quiet = TRUE))


# -------------------------------------------------------------------------
# 3. FILTER TO RTO ZONE
# -------------------------------------------------------------------------
# Keep only actual RTO region values
actual_rto <- actual_df %>%
  filter(load_area == "RTO") %>%
  select(datetime_beginning_ept, mw)

# Forecast dataset uses "RTO_COMBINED" to denote RTO region
forecast_rto <- forecast_df  %>%
  filter(forecast_area == "RTO_COMBINED") %>%
  mutate(horizon_hours = as.numeric(
      difftime(forecast_datetime_beginning_ept,evaluated_at_datetime_ept, units = "hours")
    )
  ) 

# -------------------------------------------------------------------------
# 4. SLICE FORECASTS BY HORIZON WINDOW
# -------------------------------------------------------------------------

# ---- 24-32 hour window ---------------------------------------------------
# Filter forecasts whose horizon is between 24 and 32 hours
# Sort so the first forecast in each horizon group is kept
forecast_24_32 <- forecast_rto %>%
  filter(horizon_hours >= 24, horizon_hours <= 32) %>%
  arrange(forecast_datetime_beginning_ept, horizon_hours) %>%
  group_by(forecast_datetime_beginning_ept) %>%
  slice(1) %>%          # keep the closest-ahead forecast
  ungroup()

# ---- 40-48 hour window ---------------------------------------------------
forecast_40_48 <- forecast_rto %>%
  filter(horizon_hours >=40, horizon_hours <= 48) %>%
  arrange(forecast_datetime_beginning_ept, horizon_hours) %>%
  group_by(forecast_datetime_beginning_ept) %>%
  slice(1) %>%
  ungroup()

# -------------------------------------------------------------------------
# 5. JOIN FORECASTS WITH ACTUAL LOAD
# -------------------------------------------------------------------------

# ---- Create matched actual-forecast dataframe for 24-32 hr ---------------
df_24_32 <- forecast_24_32 %>%
  inner_join(actual_rto, by = c("forecast_datetime_beginning_ept" = "datetime_beginning_ept")) %>%
  rename(
    timestamp = forecast_datetime_beginning_ept,
    forecast = forecast_load_mw,
    actual = mw
  ) %>%
  mutate(
    error_24_32     = actual - forecast,
    abs_error_24_32 = abs(error_24_32)
  )

# ---- Create matched actual-forecast dataframe for 40-48 hr ---------------
df_40_48 <- forecast_40_48 %>%
  inner_join(actual_rto, by = c("forecast_datetime_beginning_ept" = "datetime_beginning_ept")) %>%
  rename(
    timestamp = forecast_datetime_beginning_ept,
    forecast = forecast_load_mw,
    actual = mw
  ) %>%
  mutate(
    error_40_48     = actual - forecast,
    abs_error_40_48 = abs(error_40_48)
  )

# -------------------------------------------------------------------------
# 6. PAIRED t-TESTS FOR EACH HORIZON
# -------------------------------------------------------------------------

# ---- 24-32 hour horizon paired t-test ------------------------------------
t_test_paired_24_32 <- t.test(
  df_24_32$actual,
  df_24_32$forecast,
  paired = TRUE
)
t_test_paired_24_32

# ---- 40-48 hour horizon paired t-test ------------------------------------
t_test_paired_40_48 <- t.test(
  df_40_48$actual,
  df_40_48$forecast,
  paired = TRUE
)
t_test_paired_40_48
# -------------------------------------------------------------------------
# Interpretation Guide:
#
# If mean(actual - forecast) > 0 -> Model underpredicts load.
# If mean(actual - forecast) < 0 -> Model overpredicts load.
#
# Compare:
#   - p-values: Are the biases statistically significant?
#   - mean differences: How large is the average bias?
#   - confidence intervals: Are they consistently above or below zero?
#
# Larger horizons (40-48 hr) typically show more bias due to uncertainty.
# -------------------------------------------------------------------------


