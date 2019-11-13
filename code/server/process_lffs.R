# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Apply baseflow correction to LFFS LFalls forecast
# *****************************************************************************
# INPUTS
# *****************************************************************************
# lffs.daily.cfs.df - fields are date, lffs_lfalls
# lffs.hourly.cfs.df - fields are date_time, date, lffs_lfalls
# flows.daily.mgd.df
# *****************************************************************************
# OUTPUTS
# *****************************************************************************
# lffs.daily.mgd.df - with new field, lffs_lfalls_bf_corrected
# lffs.hourly.cfs.df - with new field, lffs_lfalls_bf_corrected
# *****************************************************************************

# Estimate LFalls baseflow as past 30-day minimum of daily average flows
#   - rollapply computes running stats (align = "right" for past aves)
#   - work in MGD
lffs.daily.mgd.df <- left_join(flows.daily.mgd.df, lffs.daily.cfs.df,
                                by = "date_time") %>%
  dplyr::mutate(lffs_lfalls = lffs_lfalls/mgd_to_cfs) %>%
  dplyr::select(date, lffs_lfalls, lfalls) %>%
  dplyr::mutate(min_30day_lffs = 
                  zoo::rollapply(lffs_lfalls, 30, mean,
                                 align = "right", fill = NA),
                min_30day_usgs = 
                  zoo::rollapply(lfalls, 30, mean,
                                 align = "right", fill = NA),
                lfalls_bf_correction = min_30day_usgs - min_30day_lffs,
                lffs_lfalls_bf_corrected = lffs_lfalls + lfalls_bf_correction)
  
