AEP Energy Prediction Accuracy Analysis
Denison University Data Analytics Practicum (DA 301) - Fall 2025

📋 Project Overview
This deliverables package contains the complete analysis of PJM energy demand forecast accuracy conducted by the Denison University Data Analytics team in partnership with AEP Energy. The project identifies optimal forecast windows, examines load patterns, and evaluates weather impacts on electricity demand to enhance operational planning and customer communications.
Project Duration: Fall 2025 Semester
Client: AEP Energy
Team Members: Luke Olmstead, Daniel Ha, Natalie Fieberg, Hamdan Ashfaq
Client Liaison: Josh Brown (AEP Energy)

📁 Package Contents & File Structure
AEP_Energy_Deliverables/
│
├── README.md                              # This file - complete project documentation
│
├── Reports/
│   └── Denison_DA_301_Final_Report.pdf   # Final technical report with findings & recommendations
│
├── Code/
│   ├── AEP_Energy_Visuals.Rmd            # R Markdown - visualization generation
│   └── Boxplot.ipynb                      # Python Jupyter Notebook - error distribution analysis
│
├── Data/
│   ├── Raw/                               # Original unprocessed datasets (see Data Sources section)
│   ├── Processed/                         # Cleaned and prepared datasets
│   └── METADATA.md                        # Complete data dictionary and variable descriptions
│
├── Outputs/
│   ├── Figures/                           # All generated visualizations (PNG/PDF)
│   └── Results/                           # Statistical test results and summary tables
│
└── Documentation/
    ├── Deliverables_packet_details.pdf   # Project requirements and rubric
    └── Setup_Guide.md                     # Detailed installation and setup instructions

🎯 Key Findings Summary

Optimal Forecast Window: 42-48 hour forecast window provides highest accuracy (lowest error, tightest distribution)
Systematic Bias: PJM forecasts tend to overpredict actual demand by ~930 MW at 0-hour horizon
Peak Hours: Highest demand and forecast errors occur 5-7 PM on weekdays (especially Wednesday)
Weather Impact: Temperature is the strongest predictor; wind, precipitation, and snowfall have weaker correlations
Peak Demand Days: All top 10 peak days occurred on weekdays (no weekend peaks)


🚀 Quick Start Guide
Prerequisites
For R Code (AEP_Energy_Visuals.Rmd):

R version 4.0 or higher
RStudio (recommended)
Required R packages:

r  install.packages(c("tidyverse", "ggplot2", "lubridate", "scales", 
                     "gridExtra", "knitr", "rmarkdown"))
For Python Code (Boxplot.ipynb):

Python 3.8 or higher
Jupyter Notebook or JupyterLab
Required Python packages:

bash  pip install pandas numpy matplotlib seaborn scipy jupyter
Running the Analysis
Option 1: R Visualizations (AEP_Energy_Visuals.Rmd)

Open RStudio
Open the file: Code/AEP_Energy_Visuals.Rmd
Set working directory:

r   setwd("path/to/AEP_Energy_Deliverables")

Install required packages (if not already installed - see Prerequisites)
Click "Knit" at the top of RStudio, or run:

r   rmarkdown::render("Code/AEP_Energy_Visuals.Rmd")

Output: HTML report with all visualizations will be generated

What this file does:

Loads and processes PJM actual and forecast load data
Generates heatmaps showing hourly/weekly load patterns
Creates time series plots of forecast accuracy by lead time
Produces weather correlation scatter plots
Exports high-resolution figures to Outputs/Figures/

Expected Runtime: 5-10 minutes depending on system

Option 2: Boxplot Analysis (Boxplot.ipynb)

Launch Jupyter:

bash   jupyter notebook

Navigate to: Code/Boxplot.ipynb
Click "Run All" in the Kernel menu, or run cells sequentially
Verify outputs appear inline in the notebook

What this file does:

Analyzes forecast error distribution across 6-hour windows (0-48 hour range)
Generates boxplots showing error variance by forecast horizon
Performs paired t-tests to identify systematic bias
Validates the 42-48 hour "sweet spot" finding
Exports boxplot figures to Outputs/Figures/

Expected Runtime: 2-5 minutes

📊 Data Sources & Structure
Primary Datasets
All datasets are publicly available and can be re-downloaded if needed:
1. PJM Interconnection Data

Source: PJM Data Miner
Files:

pjm_actual_load_2024-2025.csv - Actual hourly megawatt usage
pjm_forecast_7day_2024-2025.csv - 7-day ahead forecasts
pjm_historical_forecast_2024-2025.csv - Historical forecast archive


Coverage: July 2024 - October 2025
Zone: RTO (entire PJM footprint)
Temporal Resolution: Hourly

2. NOAA Weather Data

Source: NOAA National Centers for Environmental Information
File: noaa_weather_2024-2025.csv
Variables:

Average daily temperature (°F)
Average wind speed (mph)
Daily precipitation (inches)
Daily snowfall (inches)


Coverage: Stations across PJM territory
Temporal Resolution: Daily

Data Preprocessing
Key Cleaning Steps Applied:

Removed N/A values and duplicate entries
Standardized datetime formats (UTC)
Aligned forecast and actual data by timestamp
Calculated forecast errors: Error = Actual - Forecast
Computed error metrics: Absolute Error, Percent Error, MAPE, MdAPE
Merged weather data by date

See Data/METADATA.md for complete variable definitions and units.

📈 Output Files & Figures
All visualizations and results are saved to the Outputs/ directory:
Figures Generated

Figure 1 - Weekly_Load_Heatmap.png
Average hourly MW load pattern across full year 2024
Figure 2 - Forecast_Accuracy_by_Lead_Time.png
Average vs. maximum forecast error by prediction horizon (0-168 hours)
Figure 3 - Error_Distribution_Boxplot.png
Error distribution across 6-hour forecast windows (0-48 hours)
Figure 4 - Hourly_Forecast_Error_Heatmap.png
MAPE by hour of day and day of week (full year 2024)
Figure 5 - Peak_Days_Forecast_Error_Heatmap.png
MdAPE during top 10 peak demand days
Weather Scatterplots (4 plots):

Temperature vs. Daily Energy Usage
Wind Speed vs. Daily Energy Usage
Precipitation vs. Daily Energy Usage
Snowfall vs. Daily Energy Usage



Statistical Results

paired_t_test_results.csv - T-test outputs for forecast bias analysis
error_statistics_by_horizon.csv - Mean, median, SD of errors by lead time
peak_hours_summary.csv - Statistics for identified peak demand periods


🔧 Troubleshooting & Common Issues
Issue: "Package not found" error in R
Solution:
rinstall.packages("package_name")
library(package_name)
Issue: "File not found" error
Solution: Ensure working directory is set correctly:
r# In R:
getwd()  # Check current directory
setwd("path/to/AEP_Energy_Deliverables")

# In Python:
import os
os.getcwd()  # Check current directory
os.chdir("path/to/AEP_Energy_Deliverables")
Issue: Visualization not rendering in Jupyter
Solution: Add this at the top of the notebook:
python%matplotlib inline
import matplotlib.pyplot as plt
Issue: Out of memory error
Solution: Process data in chunks or increase available RAM. Consider using:
r# In R:
options(java.parameters = "-Xmx8g")  # Increase memory to 8GB

📚 Strategic Recommendations
Based on our analysis, we recommend AEP Energy:

Prioritize the 42-48 hour forecast window for operational decisions, customer notifications, and peak alerts
Focus on temperature as the primary weather variable in forecasting models; treat wind, precipitation, and snowfall as secondary factors
Target late afternoon/early evening hours (5-6 PM weekdays) for operational planning and reserve allocation
Enhance weekday peak demand forecasting using machine learning models (LSTM, GRU) to reduce the 1.45% median error during critical periods

See Final Report (pages 17-18) for detailed recommendations.

👥 Team Contributions

Luke Olmstead '27 - Power BI dashboard development, forecast accuracy evaluation
Natalie Fieberg '27 - External factors analysis, weather impact assessment
Daniel Ha '26 - Statistical testing, paired t-tests, bias analysis
Hamdan Ashfaq '26 - Python-based forecast accuracy analysis, error visualization, documentation


📞 Contact & Support
For questions about this deliverable package:

Primary Contact: Hamdan Ashfaq (ashfaq_h1@denison.edu)
Course Instructor: [Professor Name] ([email])

For questions about AEP Energy context:

Client Liaison: Josh Brown (AEP Energy)


📖 Additional Resources

Full Technical Report: Reports/Denison_DA_301_Final_Report.pdf
PJM Data Documentation: https://www.pjm.com/markets-and-operations/ops-analysis
NOAA Data Access: https://www.ncdc.noaa.gov/cdo-web/
Project GitHub Repository: [Insert link if applicable]


⚖️ Ethical Statement & Data Usage
All PJM and NOAA data used in this analysis are publicly accessible. This analysis is intended to improve forecasting accuracy and operational efficiency, ultimately benefiting millions of electricity consumers across the PJM territory. Ethical considerations around forecast reliability and customer impact are detailed in the Final Report (page 5).

📝 Version History

v1.0 (December 2025) - Initial deliverables package
Complete analysis for July 2024 - October 2025 data
All code tested and verified reproducible


✅ Reproducibility Checklist
Before using this package, verify:

 All required R packages installed
 All required Python packages installed
 Working directory set correctly
 Data files present in Data/ folder
 Sufficient disk space for outputs (~500 MB)
 METADATA.md reviewed for variable definitions


Last Updated: December 12, 2025
Package Version: 1.0
License: For educational and AEP Energy internal use only

This deliverables package was prepared as part of the Denison University Data Analytics Practicum (DA 301) in partnership with AEP Energy. All analysis, code, and documentation are the work of the Denison DA 301 Fall 2025 team.
