# *****************************************************************************
# This script imports time series inputs (ts).
# The path to the time series data is defined by /config/paths.R
# *****************************************************************************
# Inputs
# *****************************************************************************
# gages.csv - file listing USGS stream gages we use
# flows_daily_cfs.csv - current daily streamflow data
#    - daily data can be downloaded from CO-OP's Data Portal
#    - link is https://icprbcoop.org/drupal4/icprb/flow-data
#    - name appropriately then save the file to /input/ts/current/
# coop_pot_withdrawals.csv - WMA supplier hourly withdrawal data
#    - daily data can be downloaded from CO-OP's Data Portal
#    - link is https://icprbcoop.org/drupal4/products/coop_pot_withdrawals.csv
#    - save the file to /input/ts/current/
# *****************************************************************************
# Outputs
# *****************************************************************************
# flows.daily.mgd.df
#    - used to create inflows.df in reservoirs_make.R
#    - used to create potomac.data.df in potomac_flows_init.R
# demands.daily.df
# state.drought.df
#    - used in state_status_ts_init.R
#    - used in state_indices_update_func.R
# *****************************************************************************

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Import streamflow time series:
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Read list of gages: id, location, description -------------------------------
#   - e.g. 1638500, por, Potomac River at Point of Rocks
gages <- data.table::fread(paste(parameters_path, "gages.csv", sep = ""),
                           col.names = c("id", "location", "description"),
                                         data.table = FALSE)
list_gage_locations <- c("date", gages$location)

# Read daily flow data --------------------------------------------------------
flows.daily.cfs.df <- data.table::fread(
  paste(ts_path, "flows_daily_cfs.csv", sep = ""),
  header = TRUE,
  stringsAsFactors = FALSE,
  colClasses = c("character", rep("numeric", 31)), # force cols 2-32 numeric
  col.names = list_gage_locations,
  na.strings = c("eqp", "Ice", "Bkw", "", "#N/A", -999999),
  data.table = FALSE) %>%
  dplyr::mutate(date_time = as.POSIXct(date, tz = "EST")) %>%
  select(-date) %>%
  select(date_time, everything())

# Convert flows to mgd --------------------------------------------------------
func_cfs_to_mgd <- function(cfs) {round(cfs/mgd_to_cfs,0)}
flows.daily.mgd.df <- flows.daily.cfs.df %>%
  dplyr::mutate_at(2:32, func_cfs_to_mgd)

# Fill in df with constant future flows so that app won't break ---------------
#   - later these can be replace with forecasted flows
data_first_date <- head(flows.daily.mgd.df$date_time, 1)
data_last_date <- tail(flows.daily.mgd.df$date_time, 1)
data_last <- tail(flows.daily.mgd.df[, 2:32], 1)
current_year <- year(data_last_date)
year_final_date <- as.POSIXct(paste(as.character(current_year),
                                    "-12-31", sep = ""))
days_left_in_year <- as.numeric(as.POSIXct(year_final_date) 
                                - data_last_date)
next_date <- data_last_date

for(i in 1:days_left_in_year) {
  next_date <- next_date + days(1)
  next_row <- cbind(date_time = next_date, data_last)
  flows.daily.mgd.df <- rbind(flows.daily.mgd.df, next_row)
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Import a time series of recent WMA system demands and demand forecasts
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Read hourly data --------------------------------------------------------
demands.hourly.df <- data.table::fread(
  paste(ts_path, "coop_pot_withdrawals.csv", sep = ""),
  skip = 10,
  header = TRUE,
  stringsAsFactors = FALSE,
  # colClasses = c("character", rep("numeric", 6)), # force cols 2-6 numeric
  na.strings = c("", "#N/A", -999999),
  data.table = FALSE)

# Get df in necessary format --------------------------------------------------
demands.hourly.df <- demands.hourly.df %>%
  dplyr::rename_all(tolower) %>% # switch to lowercase col names
  dplyr::rename(date_time = datetime, 
                d_wssc = wssc,
                d_fw_w = fw,
                d_lw = lw) %>%
  dplyr::mutate(d_wa = wa_gf + wa_lf,
                d_fw_e = 70, d_fw_c = 20,
                d_total = d_fw_w + d_fw_e + d_fw_c + d_wssc + d_lw + d_wa,
                date = as.Date(date_time, "%Y-%m-%d")) %>%
  dplyr::select(-wa_gf, -wa_lf)

# Compute daily demands -------------------------------------------------------
demands.daily.df <- demands.hourly.df %>%
  select(-date_time) %>%
  group_by(date) %>%
  summarise_all(mean) %>%
  rename(date_time = date) %>%
  ungroup()

# Fill in df with constant future demands so that app won't break -------------
data_first_date <- head(demands.daily.df$date_time, 1)
data_last_date <- tail(demands.daily.df$date_time, 1)
data_last <- tail(demands.daily.df[, 2:8], 1)
# current_year <- year(data_last_date)
# year_final_date <- as.POSIXct(paste(as.character(current_year),
#                                     "-12-31", sep = ""))
days_left_in_year <- as.numeric(difftime(year_final_date,
                               data_last_date, units = "days"))
next_date <- data_last_date

for(i in 1:days_left_in_year) {
  next_date <- next_date + days(1)
  next_row <- cbind(date_time = next_date, data_last)
  demands.daily.df <- rbind(demands.daily.df, next_row)
}

# Fill in df with constant past demands so that app won't break ---------------
year_first_date <- paste(as.character(current_year), "-01-01", sep = "")
year_first_date <- as.Date(year_first_date)
data_first_date <- as.Date(data_first_date)
prior_length <- as.numeric(difftime(data_first_date,
                                    year_first_date, units = "days"))

# For now put in constant prior demands based on annuals ----------------------
d_fw_w0 <- 120
d_fw_c0 <- 20
d_fw_e0 <- 70
d_wa0 <- 140
d_wssc0 <- 160
d_lw0 <- 15
d_total0 <- 510
early_dates <- seq(year_first_date, by = "day", length.out = prior_length)
early_dates.df <- as.data.frame(early_dates) %>%
  rename(date_time = early_dates) %>%
  dplyr::mutate(d_total = d_total0,
                d_fw_w = d_fw_w0, d_fw_e = d_fw_e0, d_fw_c = d_fw_c0,
                d_wssc = d_wssc0,
                d_wa = d_wa0,
                d_lw = d_lw0)
demands.daily.df <- rbind(early_dates.df, demands.daily.df) %>%
  dplyr::mutate(date_time = as.POSIXct(date_time))
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
print("date_today0")
print(date_today0)
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



# #------------------------------
# #load in test data for ten day
# ten_day.df <- data.table::fread(file.path(ts_path, "/ten_day_test/ten_day_test.csv", sep=""),data.table = FALSE)
# 
# #------------------------------
# #load in data for demands from Sarah's Drupal site (if site is up, otherwise do nothing)
# if(url.exists("https://icprbcoop.org/drupal4/products/coop_pot_withdrawals.csv" == TRUE))
# {demands_raw.df <- data.table::fread("https://icprbcoop.org/drupal4/products/coop_pot_withdrawals.csv",
#                                      data.table = FALSE)}
                                        