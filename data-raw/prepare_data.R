# Data preparation script for gaa_pitches dataset
# This script downloads the current GAA pitch data from GitHub and processes it
# into the offline, bundled sf object used by the package.

library(sf)
library(dplyr)

# Download the current data from GitHub on every refresh. The source CSV is
# deliberately kept in a temporary file so it is not accidentally committed.
url <- "https://raw.githubusercontent.com/ryanmcg2203/gaapitchfinder/main/gaapitchfinder_data.csv"
data_file <- tempfile(fileext = ".csv")
download.file(url, data_file, mode = "wb", quiet = TRUE)

# Read the CSV data
pitch_data <- read.csv(data_file, stringsAsFactors = FALSE)
source_md5 <- unname(tools::md5sum(data_file))
unlink(data_file)

# Select and rename columns according to package requirements
gaa_pitches <- pitch_data %>%
  select(
    club = Club,
    pitch = Pitch,
    county = County,
    province = Province,
    latitude = Latitude,
    longitude = Longitude,
    country = Country,
    elevation = Elevation,
    annual_rainfall,
    rain_days,
    directions = Directions,
    twitter = Twitter,
    wikipedia = Wikipedia
  ) %>%
  # Filter out rows with missing coordinates
  filter(!is.na(latitude) & !is.na(longitude)) %>%
  # Convert to sf object with WGS84 coordinate system (EPSG:4326)
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)

# Reorder columns to have geometry last
gaa_pitches <- gaa_pitches %>%
  select(club, pitch, county, province, country, latitude, longitude, 
         elevation, annual_rainfall, rain_days, directions, twitter, 
         wikipedia, geometry)

# Save only the generated package data. The installed package therefore never
# needs network access to use gaa_pitches.
save(gaa_pitches, file = "data/gaa_pitches.rda", version = 2, compress = "bzip2")

# Print summary
cat("GAA Pitches dataset prepared successfully!\n")
cat("Source CSV MD5:", source_md5, "\n")
cat("Total pitches:", nrow(gaa_pitches), "\n")
cat("Counties:", length(unique(gaa_pitches$county)), "\n")
cat("Provinces:", length(unique(gaa_pitches$province[!is.na(gaa_pitches$province)])), "\n")
