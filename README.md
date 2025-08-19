# Geospatial Analysis of Energy Consumption Patterns  

## Overview  
This project analyzes **energy consumption patterns in Charlotte, NC** using geospatial, demographic, and infrastructure data. The objective was to identify clusters of high demand, explore temporal usage trends, and highlight areas for targeted **energy efficiency programs**.  

By integrating multiple datasets into a unified geospatial framework, I demonstrated how **spatial analytics can inform utility planning, distributed energy resource placement, and policy development**.  

## Data  
- **Sources:** Geospatial and utility consumption datasets for Charlotte, NC, along with demographic and building infrastructure data.  
- **Note on confidentiality:** All datasets used were public or academic resources. No sensitive or proprietary data is included.  

## Methods & Workflow  
1. **Data Cleaning & Preparation**  
   - Cleaned and standardized utility consumption data.  
   - Merged demographic, building infrastructure, and grid-level data.  

2. **Geospatial Modeling**  
   - Used R (tidyverse, sf) to integrate spatial and tabular datasets.  
   - Applied spatial modeling techniques to analyze distribution patterns.  

3. **Analysis**  
   - Identified high-demand clusters and usage trends over time.  
   - Evaluated neighborhood-level differences in energy demand.  

4. **Visualization**  
   - Built heatmaps, interactive maps, and statistical summaries.  
   - Highlighted consumption hotspots and potential areas for program targeting.  

## Key Files  
- `geospatial_energy_analysis.R` – R script for data cleaning, spatial modeling, and visualization.  
- `data/` – public datasets used for analysis (or links if too large).  
- `outputs/` – plots, maps, and summary tables.  
- `README.md` – this documentation.  

## Results / Outputs  
- Cleaned and merged multiple datasets into a reproducible geospatial framework.  
- Detected clusters of high demand across Charlotte, NC.  
- Produced heatmaps and spatial summaries showing neighborhood-level consumption patterns.  
- Demonstrated how spatial analysis can guide **energy efficiency planning** and **distributed resource allocation**.  

## How to Reproduce  
1. Clone this repo.  
2. Open `geospatial_energy_analysis.R` in RStudio.  
3. Install required packages (`tidyverse`, `sf`, `ggplot2`).  
4. Run the script to clean data, perform spatial analysis, and generate maps.  

## Author  
**Sofia Blankenship**  
- MPH, Epidemiology | Data & Analytics Professional  
- [LinkedIn Profile link here]  
