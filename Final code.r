#actually happened data
library(readr)
X2024_Actual_Load <- read_csv("Documents/DA 301/2024_Actual_Load.csv")
#forecasted Data
library(readr)
load_frcstd_hist <- read_csv("Documents/DA 301/load_frcstd_hist.csv")
###########################################################################


# Check the column names
colnames(X2024_Actual_Load)
colnames(load_frcstd_hist)

# Get a quick summary of the data types and first few rows
str(X2024_Actual_Load)
str(load_frcstd_hist)

# View the first few rows to see the data
head(X2024_Actual_Load)
head(load_frcstd_hist)
###########################################################################
library(dplyr)
library(lubridate)

# 1️⃣ Clean and filter actual data for RTO zone
actual_daily <- X2024_Actual_Load %>%
  filter(zone == "RTO") %>%   # only RTO zone
  select(datetime_beginning_ept, mw) %>%
  mutate(
    datetime = mdy_hms(datetime_beginning_ept),
    date = as_date(datetime)
  ) %>%
  group_by(date) %>%
  summarise(total_actual_mw = sum(mw, na.rm = TRUE)) %>%
  ungroup()

# 2️⃣ Clean forecast data
forecast_daily <- load_frcstd_hist %>%
  select(forecast_hour_beginning_ept, forecast_area, forecast_load_mw) %>%
  # if forecast_area matches RTO, filter it; otherwise adapt this line
  filter(forecast_area == "RTO") %>%  
  mutate(
    datetime = mdy_hms(forecast_hour_beginning_ept),
    date = as_date(datetime)
  ) %>%
  group_by(date) %>%
  summarise(total_forecast_mw = sum(forecast_load_mw, na.rm = TRUE)) %>%
  ungroup()

# 3️⃣ Combine actual and forecast data by date
daily_comparison <- actual_daily %>%
  left_join(forecast_daily, by = "date") %>%
  mutate(diff_mw = total_actual_mw - total_forecast_mw)

# 4️⃣ View result
head(daily_comparison)
#######################################################################
library(ggplot2)
library(dplyr)
library(tidyr)

# 1️⃣ Get the top 5 days by actual usage
top5_days <- daily_comparison %>%
  arrange(desc(total_actual_mw)) %>%
  slice_head(n = 5)

# 2️⃣ Reshape for plotting (long format)
top5_long <- top5_days %>%
  pivot_longer(
    cols = c(total_actual_mw, total_forecast_mw),
    names_to = "type",
    values_to = "mw"
  )

# 3️⃣ Plot
ggplot(top5_long, aes(x = as.factor(date), y = mw, fill = type)) +
  geom_col(position = "dodge") +
  labs(
    title = "Top 5 Megawatt Usage Days in 2024 (RTO Zone)",
    x = "Date",
    y = "Total Megawatt Usage",
    fill = "Type"
  ) +
  theme_minimal() +
  scale_fill_manual(
    values = c("total_actual_mw" = "steelblue", "total_forecast_mw" = "red"),
    labels = c("total_actual_mw" = "Actual Megawatt Usage", "total_forecast_mw" = "Forecasted Megawatt Usage")
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))



################################################
ggplot(top5_days, aes(x = as.factor(date), y = total_actual_mw)) +
  geom_col(fill = "steelblue") +
  labs(
    title = "Top 5 Actual Megawatt Usage Days in 2024 (RTO Zone)",
    x = "Date",
    y = "Total Actual MW"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

###################
ggplot(top5_days, aes(x = as.factor(date), y = total_forecast_mw)) +
  geom_col(fill = "red") +
  labs(
    title = "Top 5 Forecasted Megawatt Usage Days in 2024 (RTO Zone)",
    x = "Date",
    y = "Total Forecasted MW"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


