# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Apply baseflow correction to LFFS LFalls forecast
# *****************************************************************************
# INPUTS
# *****************************************************************************
# lffs.daily.cfs.df - fields are date_time, lfalls_lffs
# lffs.hourly.cfs.df - fields are date_time, date, lfalls_lffs
# flows.daily.mgd.df
# *****************************************************************************
# OUTPUTS
# *****************************************************************************
# lffs.daily.mgd.df - with new field, lfalls_lffs_bf_corrected
# lffs.hourly.cfs.df - with new field, lfalls_lffs_bf_corrected
# *****************************************************************************

# Estimate LFalls baseflow as past 30-day minimum of daily average flows
#   - rollapply computes running stats (align = "right" for past aves)
#   - work in MGD

# Add corrections to lffs daily df --------------------------------------------
lffs.daily.mgd.df <- left_join(flows.daily.mgd.df, lffs.daily.cfs.df,
                                by = "date_time") %>%
  dplyr::mutate(lfalls_lffs = round(lfalls_lffs/mgd_to_cfs, 0)) %>%
  dplyr::select(date_time, lfalls_lffs, lfalls) %>%
  dplyr::mutate(min_30day_lffs = 
                  zoo::rollapply(lfalls_lffs, 30, min,
                                 align = "right", fill = NA),
                min_30day_usgs = 
                  zoo::rollapply(lfalls, 30, min,
                                 align = "right", fill = NA),
                lfalls_bf_correction = min_30day_usgs - min_30day_lffs)
correction_today <- lffs.daily.mgd.df %>%
  filter(date_time == date_today0)

correction_today <- correction_today$lfalls_bf_correction
lffs.daily.mgd.df <- lffs.daily.mgd.df %>%
  mutate(lfalls_bf_correction = case_when(
    date_time <= date_today0 ~ lfalls_bf_correction,
    date_time > date_today0 ~ correction_today,
    TRUE ~ -9999),
    lfalls_lffs_bf_corrected = round(lfalls_lffs + 
                  lfalls_bf_correction, 0),
    lfalls_obs = lfalls,
    lfalls_lffs_daily = lfalls_lffs) %>%
  dplyr::select(date_time, lfalls_obs, lfalls_lffs_daily,
                lfalls_lffs_bf_corrected, lfalls_bf_correction)
  
# Create df with daily lffs corrections ---------------------------------------
lffs.daily.corrections.df <- lffs.daily.mgd.df %>%
  mutate(date = as.Date(date_time)) %>%
  select(-date_time) %>%
  select(date, lfalls_obs, lfalls_lffs_daily,
         lfalls_lffs_bf_corrected, lfalls_bf_correction)

lffs.hourly.mgd.df <- left_join(lffs.hourly.cfs.df,
                                 lffs.daily.corrections.df, by = "date") %>%
  mutate(lfalls_lffs = lfalls_lffs/mgd_to_cfs)