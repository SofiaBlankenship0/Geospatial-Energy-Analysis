install.packages(c("tidyverse", "sf", "leaflet", "plotly", "viridis", "scales", "tigris", "tidycensus"))
# Charlotte, NC Geospatial Energy Consumption Analysis
# Recreating spatial energy analysis with building footprints and demographics

#Data Check
print("Checking what data loaded:")
print(paste("AMI data rows:", nrow(ami_data)))
print(paste("FPL data rows:", nrow(fpl_data))) 
print(paste("Census tracts:", nrow(tracts)))

#Checking Joins
print("Checking income_data:")
print(head(income_data))
print("Columns in income_data:")
print(colnames(income_data))

#Checking if valid energy_burden_index values
if(exists("energy_tracts")) {
  print("Energy burden index summary:")
  print(summary(energy_tracts$energy_burden_index))
  print(paste("Non-NA values:", sum(!is.na(energy_tracts$energy_burden_index))))
}

#Test GEOID matching post-fix
print("Sample GEOIDs from census tracts:")
print(head(tracts$GEOID))

print("Sample GEOIDs from AMI data:")
ami_test <- read_csv("/Users/sofiablankenship/Desktop/GITHUB FILES/NC AMI Census Tracts 2022.csv") %>%
  mutate(GEOID = sprintf("%.0f", FIP))
print(head(ami_test$GEOID))

print("Do any GEOIDs match?")
print(sum(tracts$GEOID %in% ami_test$GEOID))

#Debug energy_burden_index calculation
print("Checking energy_tracts data:")
print(paste("Rows in energy_tracts:", nrow(energy_tracts)))

print("Building density summary:")
print(summary(energy_tracts$building_density))

print("Poverty indicator summary:")
print(summary(energy_tracts$poverty_indicator))

print("Estimated housing summary:")
print(summary(energy_tracts$estimated_housing))

print("Sample of energy_tracts data:")
print(head(energy_tracts %>% st_drop_geometry() %>% 
             select(GEOID, estimated_housing, poverty_indicator, building_density, energy_burden_index)))

#Load libraries
library(tidyverse)
library(sf)
library(leaflet)
library(plotly)
library(viridis)
library(scales)
library(tigris)
library(tidycensus)

#Set options
options(tigris_use_cache = TRUE)
sf_use_s2(FALSE)

# =============================================================================
# 1. LOAD AND PREPARE DATA
# =============================================================================

print("Loading datasets...")

#Set Census API key for tidycensus package 
census_api_key("075f67594318b925b48da15f49f37548c1b8e100", install = TRUE, overwrite = TRUE)

#Load census tract boundaries using tidycensus
tracts <- get_acs(
  geography = "tract",
  variables = "B01001_001", #Total pop
  state = "NC",
  county = "Mecklenburg", 
  year = 2021,
  geometry = TRUE
) %>%
  select(GEOID, NAME, geometry) %>%
  st_transform(crs = 4326)

print(paste("Loaded", nrow(tracts), "census tracts for Mecklenburg County"))

#Load AMI (Area Median Income) data
ami_data <- read_csv("/Users/sofiablankenship/Desktop/GITHUB FILES/NC AMI Census Tracts 2022.csv") %>%
  mutate(GEOID = sprintf("%.0f", FIP))  # Convert scientific notation to full number string

#Load FPL (Federal Poverty Level) data  
fpl_data <- read_csv("/Users/sofiablankenship/Desktop/GITHUB FILES/NC FPL Census Tracts 2022.csv") %>%
  mutate(GEOID = sprintf("%.0f", FIP))  # Convert scientific notation to full number string

#SKIP LOADING INDIVIDUAL BUILDINGS TO SAVE MEMORY#
#Estimate building density from census tract data
print("Skipping individual building loading to conserve memory...")
print("Using census tract estimates for building density...")

#Create dummy buildings count, estimate from tract characteristics
charlotte_buildings <- NULL

print(paste("Loaded", nrow(charlotte_buildings), "buildings in Charlotte area"))

# =============================================================================
# 2. PREPARE AMI AND FPL DATA FOR ANALYSIS
# =============================================================================

print("Processing income and poverty data...")

#Clean and combine AMI and FPL data
income_data <- ami_data %>%
  #Remove duplicates first
  distinct(GEOID, .keep_all = TRUE) %>%
  left_join(
    fpl_data %>% distinct(GEOID, .keep_all = TRUE), 
    by = "GEOID", 
    suffix = c("_ami", "_fpl"),
    relationship = "one-to-one"
  ) %>%
  #Use actual column names from your data and convert to numeric
  mutate(
    #Use UNITS from data if it exists, otherwise estimate
    estimated_housing = if("UNITS" %in% names(.)) as.numeric(UNITS) else 1600,
    estimated_pop = estimated_housing * 2.5,  # Rough estimate: 2.5 people per housing unit
    #Convert FPL150 to numeric and use as poverty indicator
    poverty_indicator = if("FPL150" %in% names(.)) as.numeric(FPL150) else 100,
    #Replace any NA values
    estimated_housing = ifelse(is.na(estimated_housing), 1600, estimated_housing),
    poverty_indicator = ifelse(is.na(poverty_indicator), 100, poverty_indicator)
  )

# =============================================================================
# 3. SPATIAL DATA INTEGRATION
# =============================================================================

print("Joining datasets...")

#Join data to tract boundaries  
energy_tracts <- tracts %>%
  left_join(income_data, by = "GEOID") %>%
  #Calculate building density using housing units instead of individual buildings
  mutate(
    tract_area = as.numeric(st_area(.)) / 1000000,  # Convert to km2
    #Use housing units as proxy for building density
    building_density = estimated_housing / tract_area,
    #Create energy burden proxy, use only building density since poverty indicator has no variation
    energy_burden_index = as.numeric(scale(building_density)[,1]),
    energy_burden_category = case_when(
      energy_burden_index > 1 ~ "Very High",
      energy_burden_index > 0.5 ~ "High", 
      energy_burden_index > -0.5 ~ "Moderate",
      energy_burden_index > -1 ~ "Low",
      TRUE ~ "Very Low"
    )
  )

print(paste("Final dataset has", nrow(energy_tracts), "census tracts"))

# =============================================================================
# 4. CREATE VISUALIZATIONS
# =============================================================================

print("Creating visualizations...")

#Static Energy Burden Heatmap
energy_heatmap <- ggplot(energy_tracts) +
  geom_sf(aes(fill = energy_burden_index), color = "white", size = 0.1) +
  scale_fill_viridis_c(
    name = "Energy Burden\nIndex",
    option = "plasma",
    direction = 1,
    labels = function(x) sprintf("%.1f", x)
  ) +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5, size = 12),
    legend.position = "bottom",
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 8)
  ) +
  labs(
    title = "Charlotte, NC: Estimated Energy Burden by Census Tract",
    subtitle = "Higher values indicate areas with greater energy affordability challenges",
    caption = "Data: U.S. Census ACS 2021, DOE LEAD Tool 2022, Microsoft Building Footprints"
  )

#Building Density vs Income Heatmap  
income_buildings <- ggplot(energy_tracts) +
  geom_sf(aes(fill = building_density), color = "white", size = 0.1) +
  scale_fill_viridis_c(
    name = "Buildings\nper km²",
    option = "viridis",
    trans = "log10",
    labels = comma_format()
  ) +
  theme_void() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    legend.position = "bottom"
  ) +
  labs(
    title = "Building Density by Census Tract",
    subtitle = "Higher density areas likely have greater energy consumption"
  )

#Interactive Map with Leaflet
create_interactive_map <- function() {
  #Create color palette
  pal <- colorNumeric(
    palette = "plasma",
    domain = energy_tracts$energy_burden_index,
    na.color = "transparent"
  )
  
  leaflet(energy_tracts) %>%
    addTiles() %>%
    addPolygons(
      fillColor = ~pal(energy_burden_index),
      weight = 1,
      opacity = 1,
      color = "white",
      dashArray = "3",
      fillOpacity = 0.7,
      popup = ~paste0(
        "<b>Census Tract: </b>", NAME, "<br>",
        "<b>Energy Burden Index: </b>", round(energy_burden_index, 2), "<br>",
        "<b>Building Density: </b>", round(building_density, 1), " per km²<br>",
        "<b>Estimated Housing: </b>", estimated_housing, "<br>",
        "<b>Estimated Population: </b>", estimated_pop
      )
    ) %>%
    addLegend(
      pal = pal,
      values = ~energy_burden_index,
      opacity = 0.7,
      title = "Energy Burden Index",
      position = "bottomright"
    ) %>%
    setView(lng = -80.8431, lat = 35.2271, zoom = 10)
}

interactive_map <- create_interactive_map()

# =============================================================================
# 5. STATISTICAL SUMMARY
# =============================================================================

print("Generating statistical summaries...")

#Summary statistics
summary_stats <- energy_tracts %>%
  st_drop_geometry() %>%
  summarise(
    total_tracts = n(),
    total_estimated_housing = sum(estimated_housing, na.rm = TRUE),
    avg_energy_burden = mean(energy_burden_index, na.rm = TRUE),
    high_burden_tracts = sum(energy_burden_category %in% c("High", "Very High"), na.rm = TRUE),
    pct_high_burden = round(high_burden_tracts / total_tracts * 100, 1),
    avg_building_density = mean(building_density, na.rm = TRUE)
  )

#Top 10 highest energy burden tracts
high_burden_tracts <- energy_tracts %>%
  st_drop_geometry() %>%
  arrange(desc(energy_burden_index)) %>%
  slice_head(n = 10) %>%
  select(NAME, energy_burden_index, building_density, estimated_housing)

#Simple correlation analysis with available variables
correlations <- energy_tracts %>%
  st_drop_geometry() %>%
  select(energy_burden_index, building_density, estimated_housing, estimated_pop) %>%
  cor(use = "complete.obs") %>%
  round(3)

# =============================================================================
# 6. DISPLAY RESULTS
# =============================================================================

print("=== CHARLOTTE ENERGY ANALYSIS RESULTS ===")
print("Summary Statistics:")
print(summary_stats)

print("\nTop 10 Highest Energy Burden Areas:")
print(high_burden_tracts)

print("\nCorrelation Matrix:")
print(correlations)

print("\nDisplaying visualizations...")
print(energy_heatmap)
print(income_buildings) 
print(interactive_map)

#Save outputs
ggsave("charlotte_energy_burden_heatmap.png", energy_heatmap, width = 12, height = 10, dpi = 300)
ggsave("charlotte_building_density.png", income_buildings, width = 12, height = 10, dpi = 300)

#Save data for further analysis
write_csv(energy_tracts %>% st_drop_geometry(), "charlotte_energy_analysis_data.csv")

print("Analysis complete, files saved to working directory.")
print("GitHub-ready files: charlotte_energy_burden_heatmap.png, charlotte_building_density.png, charlotte_energy_analysis_data.csv")
