# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Scale current input flows and withdrawals for drought exercises
# *****************************************************************************
# INPUTS
# *****************************************************************************
# /input/ts/current/flows_daily_cfs.csv - current daily streamflow data
# /input/ts/current/flows_hourly_cfs.csv - current hourly streamflow data
# /input/ts/current/coop_pot_withdrawals.csv - WMA withdrawal data
# *****************************************************************************
# OUTPUTS
# *****************************************************************************
# /input/ts/drex/flows_daily_cfs.csv
# /input/ts/drex/flows_hourly_cfs.csv
# /input/ts/drex/coop_pot_withdrawals.csv
# *****************************************************************************

# Paths -----------------------------------------------------------------------
drex_path <- "input/ts/2019_drex/"
current_path <- "input/ts/current/"

# Key drex inputs -------------------------------------------------------------
flow_scale_factor <- 0.28
withdrawals_scale_factor <- 1.4
luke_assumed_cfs <- 120
luke_min_cfs <- 120
withdr_assumed_actual_mgd <- 350 # mgd
withdr_assumed_actual_cfs <- withdr_assumed_actual_mgd*mgd_to_cfs
withdr_assumed_scaled_cfs <- withdr_assumed_actual_cfs* withdrawals_scale_factor

# Define function for use in mutate_at to scale all flows ---------------------
scale_flows_func <- function(x, scalefactor) {round(x*scalefactor, 0)}

# Read hourly withdr's from current folder and scale --------------------------
withdr.hourly.actual <- data.table::fread(
  paste(current_path, "coop_pot_withdrawals.csv", sep = ""),
  skip = 10,
  header = TRUE,
  stringsAsFactors = FALSE,
  colClasses = c("character", rep("numeric", 5)), # force cols 2-6 numeric
  na.strings = c("eqp", "Ice", "Bkw", "", "#N/A", "NA", -999999),
  data.table = FALSE) 

withdr.hourly.scaled <- withdr.hourly.actual %>%
  dplyr::mutate_at(2:6, scale_flows_func, withdrawals_scale_factor) %>%
  # write the future header
  add_row(DateTime = "DateTime", FW = "FW", WSSC = "WSSC",
          WA_GF = "WA_GF", WA_LF = "WA_LF", LW = "LW", .before = 1) %>%
  # write 10 dummy rows, to mimic file from the Data Portal
  add_row(DateTime = rep("dummy-row", 10), .before=1)

# Read daily flows from current folder and scale ------------------------------
#   - Luke and LFalls handled in special way
flows.daily.actual <- data.table::fread(
  paste(current_path, "flows_daily_cfs.csv", sep = ""),
  header = TRUE,
  stringsAsFactors = FALSE,
  colClasses = c("character", rep("numeric", 31)), # force cols 2-32 numeric
  col.names = list_gage_locations, # 1st column is "date"
  na.strings = c("eqp", "Ice", "Bkw", "", "#N/A", -999999),
  data.table = FALSE) %>%
  dplyr::mutate(date = as.Date(date)) # rewrite with 1st column as "date"

# Apply scale factor
flows.daily.scaled <- flows.daily.actual %>%
  # convert LFalls obs to LFalls adj before scaling
  mutate(lfalls = lfalls + withdr_assumed_actual_cfs) %>% 
  dplyr::mutate_at(2:32, scale_flows_func, flow_scale_factor) %>%
  # convert LFalls adj back to LFalls
  dplyr::mutate(lfalls = lfalls - withdr_assumed_scaled_cfs) %>%
  # and Luke flow is assumed to be kept above min by NBr reservoirs
  dplyr::mutate(luke = case_when(
    luke < luke_min_cfs ~ luke_min_cfs,
    luke >= luke_min_cfs ~ luke,
    TRUE ~ -999.9))

# Read hourly flows from current folder and scale -----------------------------
flows.hourly.actual <- data.table::fread(
  paste(current_path, "flows_hourly_cfs.csv", sep = ""),
  header = TRUE,
  stringsAsFactors = FALSE,
  colClasses = c("character", rep("numeric", 31)), # force cols 2-32 numeric
  col.names = list_gage_locations, # 1st column is "date"
  na.strings = c("eqp", "Ice", "Bkw", "", "#N/A", -999999),
  data.table = FALSE) %>%
  dplyr::mutate(date = as.POSIXct(date)) # rewrite with 1st column as "date"

# Apply scale factor
flows.hourly.scaled <- flows.hourly.actual %>%
  # convert LFalls obs to LFalls adj before scaling
  mutate(lfalls = lfalls + withdr_assumed_actual_cfs) %>%
  dplyr::mutate_at(2:32, scale_flows_func, flow_scale_factor) %>%
  # convert LFalls adj back to LFalls
  dplyr::mutate(lfalls = lfalls - withdr_assumed_scaled_cfs) %>%
  # and Luke flow is assumed to be kept above min by NBr reservoirs
  dplyr::mutate(luke = case_when(
    luke < luke_min_cfs ~ luke_min_cfs,
    luke >= luke_min_cfs ~ luke,
    TRUE ~ -999.9))

# Read hourly LFFS flows from current folder and scale ------------------------
flows.lffs.actual <- data.table::fread(
  paste(current_path, "PM7_4820_0001.flow", sep = ""),
  skip = 25,
  header = FALSE,
  stringsAsFactors = FALSE,
  colClasses = c(rep("numeric", 6)), # force cols to numeric
  col.names = c("year", "month", "day", "minute", "second", "lfalls_lffs"),
  data.table = FALSE) %>%
  filter(year >= current_year) # %>%

flows.lffs.scaled <- flows.lffs.actual %>%
  # convert LFalls obs to LFalls adj before scaling
  dplyr::mutate(lfalls_lffs = lfalls_lffs + withdr_assumed_actual_cfs) %>%
  # apply scale factor
  dplyr::mutate(lfalls_lffs = lfalls_lffs*flow_scale_factor) %>%
  # convert LFalls adj back to LFalls
  dplyr::mutate(lfalls_lffs = lfalls_lffs - withdr_assumed_scaled_cfs) %>%
  # write 10 dummy rows, to mimic file from the Data Portal
  add_row(year = rep("dummy-row", 25), .before=1)

# Write to drex folder --------------------------------------------------------
write_csv(flows.daily.scaled, paste(drex_path, 
                                    "flows_daily_cfs.csv", sep=""))

write_csv(flows.hourly.scaled, paste(drex_path,
                                     "flows_hourly_cfs.csv", sep=""))

write_csv(withdr.hourly.scaled, paste(drex_path,
                              "coop_pot_withdrawals.csv", sep=""),
                              col_names = FALSE)

write_csv(flows.lffs.scaled, paste(drex_path,
                                      "PM7_4820_0001.flow", sep=""),
          col_names = FALSE)
