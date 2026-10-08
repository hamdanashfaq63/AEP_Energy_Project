# Data

## Included

`hour_load_metered.csv`: hourly metered load from PJM for every zone and load area, July 1 to October 31, 2025 (88,560 rows). Key columns: `datetime_beginning_ept` (hour beginning, Eastern prevailing time), `zone`, `load_area`, `mw`, `is_verified`. Rows with `zone == "RTO"` and `load_area == "RTO"` cover the whole PJM footprint.

## Not included (too large for the repository)

Download from [PJM Data Miner 2](https://dataminer2.pjm.com/) and place in this folder:

| File | Data Miner feed ID | Used by |
|---|---|---|
| `2024_Actual_Load.csv` | `hrl_load_metered` (2024) | `R/01_daily_actual_vs_forecast_2024.R` |
| `load_frcstd_hist.csv` | `load_frcstd_hist` | `R/01_daily_actual_vs_forecast_2024.R` |
| `forecasted_hourly_transmission_load.csv` | `load_frcstd_7_day` | `R/02_forecast_bias_tests_and_heatmaps.R` |
| `actual_Load.csv` | `hrl_load_metered` (2024) | `R/02_forecast_bias_tests_and_heatmaps.R` |

Daily weather (average temperature, wind speed, precipitation, snowfall) came from [NOAA Climate Data Online](https://www.ncei.noaa.gov/cdo-web/) for stations across the PJM territory.
