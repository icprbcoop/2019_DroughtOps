# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# This script imports time series inputs (ts).
# The path to the time series data is defined by /config/paths.R
# *****************************************************************************
# INPUTS
# *****************************************************************************
# gages.csv - file listing USGS stream gages we use
# flows_daily_cfs.csv - current daily streamflow data
#   - code set up so that these time series begin on Jan 1 of current year
#   - daily data can be downloaded from CO-OP's Data Portal
#   - link is https://icprbcoop.org/drupal4/icprb/flow-data
#   - name appropriately then save the file to /input/ts/current/
# flows_hourly_cfs.csv - current hourly streamflow data
#   - hourly data can be downloaded from CO-OP's Data Portal
#   - link is https://icprbcoop.org/drupal4/icprb/flow-data
#   - grab last few days of data and paste into existing file (or memory error!)
#   - file is in /input/ts/current/
# coop_pot_withdrawals.csv - WMA supplier hourly withdrawal data
#   - daily data can be downloaded from CO-OP's Data Portal
#   - link is https://icprbcoop.org/drupal4/products/coop_pot_withdrawals.csv
#   - save the file to /input/ts/current/
# state_drought_status.csv - time series of gw, precip, etc indices for MD, VA
#   - this is currently a dummy file from 2018 DREX
# Fake reservoir ops dfs, e.g., drex2018_output_sen.csv
#   - used to initialize the res.ts.df's until I decide how to handle this
# *****************************************************************************
# OUTPUTS
# *****************************************************************************
# flows.daily.csv.df
#   - used in complete_daily_flows.R to create flows.daily.mgd.df
# demands.daily.df - really withdrawals right now
#   - used to create potomac.data.df in potomac_flows_init.R
#   - used in sim_main_func in call to simulation_func
#   - used in sim_add_days_func in call to simulation_func
# state.drought.df
#   - used in state_status_ts_init.R
#   - used in state_indices_update_func.R
# sen.ts.df00, pat.ts.df00, ..., from date_start to date_end (from parameters)
# *****************************************************************************

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Import daily streamflow time series:
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Read list of gages: has id, location, description ---------------------------
#   - e.g. 1638500, por, Potomac River at Point of Rocks
gages <- data.table::fread(paste(parameters_path, "gages.csv", sep = ""),
                           header = TRUE,
                           data.table = FALSE)
list_gage_locations <- c("date", gages$location)
llen <- length(list_gage_locations)
gage_locations <- list_gage_locations[2:llen]
gage_locations <- as.list(gage_locations)

# Will make use of first and last day of current year
date_dec31 <- lubridate::ceiling_date(date_today0, unit = "year") - 1
date_jan1 <- lubridate::floor_date(date_today0, unit = "year")

# Read daily flow data --------------------------------------------------------
#   - for daily data use as.Date - getting rid of time
flows.daily.cfs.df0 <- data.table::fread(
  paste(ts_path, "flows_daily_cfs.csv", sep = ""),
  header = TRUE,
  stringsAsFactors = FALSE,
  colClasses = c("character", rep("numeric", 31)), # force cols 2-32 numeric
  col.names = list_gage_locations, # 1st column is "date"
  na.strings = c("eqp", "Ice", "Bkw", "", "#N/A", "NA", -999999),
  data.table = FALSE) %>%
  dplyr::mutate(date_time = as.Date(date)) %>%
  select(-date) %>%
  filter(!is.na(date_time)) %>%
  select(date_time, everything()) %>%
  arrange(date_time)

# Identify the last date with daily flow data
flowday_last <- tail(flows.daily.cfs.df0, 1)$date_time

# Add rest of the year's dates to this df; added flow values = NA
#  - this seems to make the app more robust if missing data
flows.daily.cfs.df <- flows.daily.cfs.df0 %>%
  add_row(date_time = seq.Date(flowday_last + 1, date_dec31, by = "day"))

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Import hourly streamflow time series:
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Read hourly flow data -------------------------------------------------------
#   - for hourly data use as.POSIXct
flows.hourly.cfs.df <- data.table::fread(
  paste(ts_path, "flows_hourly_cfs.csv", sep = ""),
  header = TRUE,
  stringsAsFactors = FALSE,
  colClasses = c("character", rep("numeric", 31)), # force cols 2-32 numeric
  col.names = list_gage_locations, # 1st column is "date"
  na.strings = c("eqp", "Ice", "Bkw", "", "#N/A", "NA", -999999),
  data.table = FALSE) %>%
  # mutate(date_time = date)
  dplyr::mutate(date_time = as.POSIXct(date)) %>%
  select(-date) %>%
  arrange(date_time) %>%
  filter(!is.na(date_time)) %>% # sometime these are sneaking in
  head(-1) %>% # the last record is sometimes missing most data
  select(date_time, everything())

# Add 3 days of rows; added flow values = NA
last_hour <- tail(flows.hourly.cfs.df$date_time, 1)
last_hour <- last_hour + lubridate::hours(1)
flows.hourly.cfs.df <- flows.hourly.cfs.df %>%
  add_row(date_time = seq.POSIXt(last_hour, length.out = 72, by = "hour"))

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Import a time series of recent WMA system withdrawals and withdr forecasts
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Read hourly withdrawal data -------------------------------------------------
withdr.hourly.df0 <- data.table::fread(
  paste(ts_path, "coop_pot_withdrawals.csv", sep = ""),
  skip = 12,
  header = TRUE,
  stringsAsFactors = FALSE,
  # colClasses = c("character", rep("numeric", 6)), # force cols 2-6 numeric
  na.strings = c("", "#N/A", -999999),
  data.table = FALSE)

# Get df in necessary format --------------------------------------------------
withdr.hourly.df <- withdr.hourly.df0 %>%
  dplyr::rename_with(tolower) %>% # switch to lowercase col names
  dplyr::rename(date_time = datetime,
                w_wssc = wssc,
                w_fw_w = fw,
                w_lw = lw) %>%
  filter(!is.na(date_time)) %>% # sometime these are sneaking in
  dplyr::mutate(date_time = as.POSIXct(date_time, tz = "EST"),
                date = round_date(date_time, unit = "days"),
                w_wa = wa_gf + wa_lf,
                w_fw_e = 70, w_fw_c = 20,
                # total Potomac withdrawals:
                w_pot_total = w_fw_w + w_wssc + w_lw + w_wa
                )  %>%
  dplyr::select(-wa_gf, -wa_lf)

# Compute daily withdrawals ---------------------------------------------------
demands.daily.df <- withdr.hourly.df %>%
  select(-date_time) %>%
  group_by(date) %>%
  # summarise_all(mean) %>%
  summarise(across(everything(), mean), .groups = "keep") %>%
  # temporarily go back to d (demand) instead of w (withdrawal)
  rename(date_time = date, d_wa = w_wa, d_fw_w = w_fw_w, d_lw = w_lw,
         d_wssc = w_wssc, d_pot_total = w_pot_total, 
         d_fw_e = w_fw_e, d_fw_c = w_fw_c) %>%
  mutate(date_time = as.Date(date_time)) %>%
  ungroup()

# # Fill in df with full year of demands so that app won't break --------------
ncols <- length(demands.daily.df[1,])
data_first_date <- head(demands.daily.df$date_time, 1)
data_last_date <- tail(demands.daily.df$date_time, 1)
data_last <- tail(demands.daily.df[, 2:ncols], 1)
data_first <- head(demands.daily.df[, 2:ncols], 1)
current_year <- year(data_last_date)
days_left_in_year <- as.numeric(date_dec31 - data_last_date)
next_date <- data_last_date

for(i in 1:days_left_in_year) {
  next_date <- next_date + days(1)
  next_row <- cbind(date_time = next_date, data_last)
  demands.daily.df <- rbind(demands.daily.df, next_row)
}

# Fill in df with constant past demands so that app won't break ---------------
data_first_date <- as.Date(data_first_date)
days_prior_in_year <- as.numeric(difftime(data_first_date,
                                          date_jan1, 
                                    units = "days"))
prior_date <- data_first_date
for(i in 1:days_prior_in_year) {
  prior_date <- prior_date - days(1)
  prior_row <- cbind(date_time = prior_date, data_first)
  demands.daily.df <- rbind(demands.daily.df, prior_row)
}
demands.daily.df <- demands.daily.df %>%
  dplyr::arrange(date_time) %>%
  dplyr::mutate(date_time = round_date(date_time, unit = "days"))

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Read the datafile with hourly LFFS forecasts
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Read LFFS LFalls hourly data ------------------------------------------------
lffs.hourly.cfs.all.df <- data.table::fread(
  # paste(ts_path, "PM7_4820_0001.flow", sep = ""),
  "http://icprbcoop.org/upload01/PM7_4820_0001.flow",
  skip = 25,
  header = FALSE,
  stringsAsFactors = FALSE,
  colClasses = c(rep("numeric", 6)), # force cols to numeric
  col.names = c("year", "month", "day", "minute", "second", "lfalls_lffs"),
  # na.strings = c("eqp", "Ice", "Bkw", "", "#N/A", "NA", -999999),
  data.table = FALSE) 

lffs.hourly.cfs.df <- lffs.hourly.cfs.all.df %>%
  filter(year >= current_year) %>%
  dplyr::mutate(date_time = 
                  lubridate::make_datetime(year, month, 
                                           day, minute, second),
                date = lubridate:: round_date(date_time, unit = "days"),
                date = as.Date(date)) %>%
  select(date_time, date, lfalls_lffs)

# Compute LFFS LFalls daily flows ---------------------------------------------
lffs.daily.cfs.df <- lffs.hourly.cfs.df %>%
  select(-date_time) %>%
  group_by(date) %>%
  summarise(lfalls_lffs = mean(lfalls_lffs)) %>%
  mutate(date_time = as.Date(date)) %>%
  select(date_time, lfalls_lffs) %>%
  ungroup()

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Import time series representing state drought status.
#   - temporarily just use time series from 2018drex.
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# 
state.drought.df <- data.table::fread(paste(ts_path, "state_drought_status.csv", sep = ""),
                                      data.table = FALSE) %>%
  dplyr::mutate(date_time = as.Date(date_time)) %>%
  dplyr::select(date_time, 
                gw_va_shen, p_va_shen, sw_va_shen, r_va_shen,
                gw_va_nova, p_va_nova, sw_va_nova, r_va_nova,
                gw_md_cent, p_md_cent, sw_md_cent, r_md_cent,
                gw_md_west, p_md_west, sw_md_west, r_md_west,
                region_md_cent, region_md_west
                ) %>%
  dplyr:: filter(date_time <= date_end,
                 date_time >= date_start)
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Import reservoir dfs - this is a temporary fix to get us going in 2019
#   - just importing tables outputted by 2018drex to serve as temporary reservoir data frames
#   - these will be used to initialize the res dfs from date_start to date_today0 (ie today())
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# print("date_today0")
# print(date_today0)
sen.ts.df00 <- data.table::fread(paste(ts_path, "drex2018_output_sen.csv", sep = ""),
                                data.table = FALSE) %>%
  dplyr::mutate(date_time = as.Date(date_time)) %>%
  dplyr:: filter(date_time <= date_end,
                 date_time >= date_start)
jrr.ts.df00 <- data.table::fread(paste(ts_path, "drex2018_output_jrr.csv", sep = ""),
                                data.table = FALSE) %>%
  dplyr::mutate(date_time = as.Date(date_time)) %>%
  dplyr:: filter(date_time <= date_end,
                 date_time >= date_start)
occ.ts.df00 <- data.table::fread(paste(ts_path, "drex2018_output_occ.csv", sep = ""),
                                data.table = FALSE) %>%
  dplyr::mutate(date_time = as.Date(date_time)) %>%
  dplyr:: filter(date_time <= date_end,
                 date_time >= date_start)
pat.ts.df00 <- data.table::fread(paste(ts_path, "drex2018_output_pat.csv", sep = ""),
                                data.table = FALSE) %>%
  dplyr::mutate(date_time = as.Date(date_time)) %>%
  dplyr:: filter(date_time <= date_end,
                 date_time >= date_start)

#----------------------------------------shapefile load----------------------------------
# read map shapefiles in ---------------------
# Luke - CS July 2020: the lines below cause errors,
# but the variables are never used so I'm commenting out
# clipcentral = readOGR(dsn=map_path, layer = "clipcentral")
# western_dslv = readOGR(dsn=map_path, layer = "western_dslv")

#transform map shapefiles  ---------------------
# Luke - CS July 2020: the lines below cause errors,
# but the variables are never used so I'm commenting out
# clipcentral_t <- spTransform(clipcentral, CRS("+init=epsg:4326"))
# western_region_t <- spTransform(western_dslv, CRS("+init=epsg:4326"))
#----------------------------------------------------------------------------------------


#----------------------drought maps updating---------------------------------------------
# Luke - these functions seem to be broken - are hanging up

# calls function to get the latest version of the maryland drought map
# md_drought_map = md_drought_map_func(date_today0)
md_drought_map <- readPNG("input/MD_droughtmap_temp.png")

#calls function to get the latest version of the virginia drought map
#---toggle
##for day to day

# va_drought_map = va_drought_map_func()
va_drought_map = readPNG("input/VA_droughtmap_temp.png")
##to publish
# project.dir <- rprojroot::find_rstudio_root_file()
# va_drought_map = file.path(project.dir,'/global/images/va_drought_placeholder.png')
#---
#----------------------------------------------------------------------------------------


# #------------------------------
# #load in test data for ten day
# ten_day.df <- data.table::fread(file.path(ts_path, "ten_day_test/ten_day_test.csv", sep=""),
# data.table = FALSE)
# 
# #------------------------------
# #load in data for demands from Sarah's Drupal site (if site is up, otherwise do nothing)
# if(url.exists("https://icprbcoop.org/drupal4/products/coop_pot_withdrawals.csv" == TRUE))
# {demands_raw.df <- data.table::fread("https://icprbcoop.org/drupal4/products/coop_pot_withdrawals.csv",
#                                      data.table = FALSE)}
                                        