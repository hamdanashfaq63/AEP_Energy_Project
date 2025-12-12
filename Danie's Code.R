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
