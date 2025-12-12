# July - October, 2025 t-test
library(tidyverse)
library(httr2)
library(lubridate)
library(ggplot2)

actual_df1 <- read_csv("hour_load_metered.csv")
forecast_df1 <- read_csv("forecasted_hourly_transmission_load.csv")

actual_df1 <- actual_df1 %>%
  mutate(datetime_beginning_ept = mdy_hms(datetime_beginning_ept))

forecast_df1 <- forecast_df1 %>%
  mutate(forecast_datetime_beginning_ept = ymd_hms(forecast_datetime_beginning_ept))

actual_df1_rto <- actual_df1 %>%
  filter(zone == "RTO")

forecast_df1_rto <- forecast_df1 %>%
  filter(forecast_area == "RTO_COMBINED") %>%
  mutate(forecast_area = "RTO")

merged_df1 <- actual_df1 %>%
  inner_join(forecast_df1_rto,
             by = c("datetime_beginning_ept" = "forecast_datetime_beginning_ept",
                    "zone" = "forecast_area"))

# July - October, 2025 t-test
t.test(merged_df1$mw, merged_df1$forecast_load_mw, paired = TRUE)
#The model underpredicts megawatts by 970


#Chi-square test for RTO region
rto_df1 <- merged_df1 %>%
  mutate(
    actual_cat = cut(mw, breaks = 3, labels = c("Low", "Med", "High")),
    forecast_cat = cut(forecast_load_mw, breaks = 3, labels = c("Low", "Med", "High"))
  )
chisq.test(tbl)  
  t.test(merged_df1$mw, merged_df1$forecast_load_mw, paired = TRUE)







#Forecast Error Over Time(Actual - Forecast) July-October 2025
merged_df1 %>%
  ggplot(aes(x = datetime_beginning_ept, y = error)) +
  geom_line(alpha = 0.4) +
  geom_smooth(color = "red", method = "loess") +
  labs(title="Forecast Error Over Time (Actual - Forecast) July-October 2025",
       y="MegaWatt Error", x ="Months")










#Forecast Bias by GHour by Day(Actual - Forecast)
rto_df1 <- rto_df1 %>%
  mutate(error = mw - forecast_load_mw)

rto_df1 <- rto_df1 %>%
  mutate(hour = lubridate::hour(datetime_beginning_ept))

hourly_bias <- rto_df1 %>%
  group_by(hour) %>%
  summarise(mean_error = mean(error), .groups = "drop")

hourly_bias

library(ggplot2)

ggplot(hourly_bias, aes(x = hour, y = mean_error)) +
  geom_line(color = "steelblue", size = 1.1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Forecast Bias by Hour of Day (Actual - Forecast)",
    x = "Hour of Day (EPT)",
    y = "Mean Error (MW)"
  ) +
  theme_minimal()













#HEATMAP for entire year of 2024
library(tidyverse)
library(lubridate)
library(viridis)
library(forcats)


df <- read_csv("actual_Load.csv")
                      

# ---- 2) parse time & derive features ----
df <- df %>%
  mutate(
    datetime = parse_date_time(datetime_beginning_ept,
                               orders = c("mdy HMS", "mdY IMS p")),
    date = as_date(datetime),
    hour = hour(datetime),
    wday = wday(datetime, label = TRUE, abbr = FALSE, week_start = 1)
    # Monday = 1, labels "Monday","Tuesday",…,"Sunday"
  )

#3) filter to RTO zone
rto <- df %>%
  filter(zone == "RTO") %>%
  select(wday, hour, mw) %>%
  filter(!is.na(mw))

#4) average load by weekday & hour
heat <- rto %>%
  group_by(wday, hour) %>%
  summarise(avg_mw = mean(mw, na.rm = TRUE), .groups = "drop")

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














#Paired t-test (24-32 hour interval)  (40-48hour interval)!
library(tidyverse)
library(lubridate)
library(viridis)
library(forcats)
actual_df <- read_csv("hour_load_metered.csv", show_col_types = FALSE)
forecast_df <- read_csv("forecasted_hourly_transmission_load.csv", show_col_types = FALSE)

actual_df <- actual_df %>%
  mutate(datetime_beginning_ept = mdy_hms(datetime_beginning_ept, quiet = TRUE))

forecast_df <- forecast_df %>%
  mutate(evaluated_at_datetime_ept = ymd_hms(evaluated_at_datetime_ept, quiet = TRUE))

actual_rto <- actual_df %>%
  filter(load_area == "RTO") %>%
  select(datetime_beginning_ept, mw)

forecast_rto <- forecast_df  %>%
  filter(forecast_area == "RTO_COMBINED") %>%
  mutate(horizon_hours = as.numeric(
      difftime(forecast_datetime_beginning_ept,evaluated_at_datetime_ept, units = "hours")
    )
  ) 

forecast_24_32 <- forecast_rto %>%
  filter(horizon_hours >= 24, horizon_hours <= 32) %>%
  arrange(forecast_datetime_beginning_ept, horizon_hours) %>%
  group_by(forecast_datetime_beginning_ept) %>%
  slice(1) %>%          # keep the closest-ahead forecast
  ungroup()

forecast_40_48 <- forecast_rto %>%
  filter(horizon_hours >=40, horizon_hours <= 48) %>%
  arrange(forecast_datetime_beginning_ept, horizon_hours) %>%
  group_by(forecast_datetime_beginning_ept) %>%
  slice(1) %>%
  ungroup()

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

t_test_paired_24_32 <- t.test(
  df_24_32$actual,
  df_24_32$forecast,
  paired = TRUE
)
t_test_paired_24_32

t_test_paired_40_48 <- t.test(
  df_40_48$actual,
  df_40_48$forecast,
  paired = TRUE
)
t_test_paired_40_48





