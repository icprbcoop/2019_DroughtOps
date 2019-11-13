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
flow_scale_factor <- 0.35
withdrawals_scale_factor <- 1.5
luke_assumed_cfs <- 120
luke_min_cfs <- 120

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

# Compute recent Potomac withdrawal to estimate LFalls adj --------------------
withdr_yesterday <- withdr.hourly.actual %>%
  tail(24) %>%
  mutate(withdr_total = FW + WSSC + WA_GF + WA_LF + LW) %>%
  summarise_at(2:7, mean)
withdr_pot_actual_cfs <- mgd_to_cfs*withdr_yesterday$withdr_total
withdr_pot_scaled_cfs <- mgd_to_cfs*withdr_pot_actual_cfs*withdrawals_scale_factor

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

# LFalls should be converted to LFalls adj before scaling
flows.daily.scaled <- flows.daily.actual %>%
  mutate(lfalls = lfalls + withdr_pot_actual_cfs)
  
# Apply scale factor
flows.daily.scaled <- flows.daily.scaled %>%
  dplyr::mutate_at(2:32, scale_flows_func, flow_scale_factor)

# But Luke flow is assumed to be kept above min by NBr reservoirs
flows.daily.scaled <- flows.daily.scaled %>%
  dplyr::mutate(luke = case_when(
    luke < luke_min_cfs ~ luke_min_cfs,
    luke >= luke_min_cfs ~ luke,
    TRUE ~ -999.9))

# Convert LFalls adj back to LFalls
flows.daily.scaled <- flows.daily.scaled %>%
  mutate(lfalls = lfalls - withdr_pot_scaled_cfs)

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

flows.hourly.scaled <- flows.hourly.actual %>%
  dplyr::mutate_at(2:32, scale_flows_func, flow_scale_factor) %>%
  dplyr::mutate(luke = case_when(
    luke < luke_min_cfs ~ luke_min_cfs,
    luke >= luke_min_cfs ~ luke,
    TRUE ~ -999.9)
  )

# Write to drex folder --------------------------------------------------------
write_csv(flows.daily.scaled, paste(drex_path, 
                                    "flows_daily_cfs.csv", sep=""))

write_csv(flows.hourly.scaled, paste(drex_path,
                                     "flows_hourly_cfs.csv", sep=""))

write_csv(withdr.hourly.scaled, paste(drex_path,
                              "coop_pot_withdrawals.csv", sep=""),
                              col_names = FALSE)
