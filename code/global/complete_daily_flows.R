# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Create full year of daily time series - so simulation doesn't break
# *****************************************************************************
# INPUTS
# *****************************************************************************
# flows_daily_cfs.csv - current downloaded daily flow data, beginning Jan 1
# demands.daily.df - WMA supplier daily withdrawal data
# *****************************************************************************
# OUTPUTS
# *****************************************************************************
# flows.daily.mgd.df
#   - used to create inflows.df in reservoirs_make.R
#   - used to create potomac.data.df in potomac_flows_init.R
# *****************************************************************************

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Add future flows to selected gages, estimated by simple "recession" algorithm
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Convert flows to mgd --------------------------------------------------------
func_cfs_to_mgd <- function(cfs) {round(cfs/mgd_to_cfs,0)}
flows.daily.mgd.df <- flows.daily.cfs.df %>%
  dplyr::mutate_at(2:32, func_cfs_to_mgd)

# Grab the 3 most recent records, for use in recession estimates --------------
flows.last3days.df <- tail(flows.daily.mgd.df, 3)
# Minimum of past 3 days flow will be starting point for recessions
recess_mins <- flows.last3days.df %>%
  summarise_all(min)

# Find last day of current year -----------------------------------------------
data_first_date <- head(flows.daily.mgd.df$date_time, 1)
data_last_date <- tail(flows.daily.mgd.df$date_time, 1)
data_last <- tail(flows.daily.mgd.df[, 2:32], 1)
current_year <- year(data_last_date)
year_final_date <- as.Date(paste(as.character(current_year),
                                 "-12-31", sep = ""))
days_left_in_year <- as.numeric(year_final_date 
                                - data_last_date)
next_date <- data_last_date

# Add future dates up to end of year to df ------------------------------------
flows.daily.mgd.df <- flows.daily.mgd.df %>%
  add_row(date_time = seq.Date(date_today0 + 1, year_final_date, by = "day"))

# Add Potomac withdrawals -----------------------------------------------------
flows.daily.mgd.df <- left_join(flows.daily.mgd.df, demands.daily.df,
                                by = "date_time")

# Find the dates in which the min flow occurred -------------------------------

flows.last3days.df <- flows.last3days.df %>%
  arrange(por)
date_min_por <- flows.last3days.df$date_time[1]

flows.last3days.df <- flows.last3days.df %>%
  arrange(lfalls)
date_min_lfalls <- flows.last3days.df$date_time[1]

flows.last3days.df <- flows.last3days.df %>%
  arrange(monoc_jug)
date_min_monoc_jug <- flows.last3days.df$date_time[1]

flows.last3days.df <- flows.last3days.df %>%
  arrange(seneca)
date_min_seneca <- flows.last3days.df$date_time[1]

flows.last3days.df <- flows.last3days.df %>%
  arrange(goose)
date_min_goose <- flows.last3days.df$date_time[1]

# Compute recession flows for future dates ------------------------------------
flows.daily.mgd.df <- flows.daily.mgd.df %>%
  
  # recess por:
  dplyr::mutate(por = case_when(
                  date_time <= date_today0 ~ por,
                  date_time > date_today0 ~ recess_mins$por
                  *exp(-0.04*as.numeric((date_time - date_min_por))),
                  TRUE ~ -9999.9)) %>%
  
  # recess Goose
  dplyr::mutate(goose = case_when(
    date_time <= date_today0 ~ goose,
    date_time > date_today0 ~ recess_mins$goose
    *exp(-0.04*as.numeric((date_time - date_min_goose))),
    TRUE ~ -9999.9)) %>%
  
  # recess Seneca Cr (later should take into acc. wwtps, releases)
  dplyr::mutate(seneca = case_when(
    date_time <= date_today0 ~ seneca,
    date_time > date_today0 ~ recess_mins$seneca
    *exp(-0.04*as.numeric((date_time - date_min_seneca))),
    TRUE ~ -9999.9)) %>%
  
  # recess Monocacy, Jug Br
  dplyr::mutate(monoc_jug = case_when(
    date_time <= date_today0 ~ monoc_jug,
    date_time > date_today0 ~ recess_mins$monoc_jug
    *exp(-0.04*as.numeric((date_time - date_min_monoc_jug))),
    TRUE ~ -9999.9)) %>%
  
  # recess L Falls itself - just to improve look of graph
  dplyr::mutate(lfalls = case_when(
    date_time <= date_today0 ~ lfalls,
    date_time > date_today0 ~ recess_mins$lfalls
    *exp(-0.04*as.numeric((date_time - date_min_lfalls))),
    TRUE ~ -9999.9))
  
# Predict LFalls from upstream gages using constant lags ----------------------
flows.daily.mgd.df <- flows.daily.mgd.df %>%
  dplyr::mutate(lfalls_from_upstr = lag(por, 2) + lag(monoc_jug, 2)
                + lag(goose, 1) + lag(seneca, 1) - lag(d_pot_total, 1))


