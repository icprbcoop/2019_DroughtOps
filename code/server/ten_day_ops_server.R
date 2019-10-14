# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Create plot and values related to 10-day operations
# *****************************************************************************
# INPUTS
# *****************************************************************************
# flows_daily_cfs.csv - current daily streamflow data
# demands.daily.df - WMA supplier daily withdrawal data
# *****************************************************************************
# OUTPUTS
# *****************************************************************************
# output$ten_day - graph of relevant flows
# output$9_day_deficit - estimated need at LFalls 9 days hence, MGD
# output$9_day_luke_target, cfs
# *****************************************************************************
# Need to choose the correct "today" - right now this will do -----------------
date_today_ops <- as.POSIXct(today())

# Create 10-day df with all the data of interest ------------------------------
ops_10day.df <- left_join(flows.daily.mgd.df, 
                          demands.daily.df, by = "date_time") %>%
  dplyr::filter(date_time < date_today_ops + lubridate::days(20)) %>%
  dplyr::filter(date_time > date_today_ops - lubridate::days(12)) %>%
  dplyr::select(date_time, lfalls, luke, kitzmiller, barnum,
                bloomington, barton, d_total)

# Prepare data for LFalls flow plot -------------------------------------------
lfalls_10day.plot.df <- ops_10day.df %>%
  dplyr::select(date_time, lfalls, d_total) %>%
  gather(key = "site", value = "flow", -date_time)

# Create LFalls flow plot -----------------------------------------------------
output$ten_day_plot <- renderPlot({
  ggplot(lfalls_10day.plot.df, aes(x = date_time, y = flow)) + 
    geom_line(aes(colour = site, size = site)) +
    scale_color_manual(values = c("red", "deepskyblue1")) +
    scale_size_manual(values = c(1, 2))
})
  
# Prepare data for N Br flows plot --------------------------------------------
#   - flows at Luke and flows into and out of reservoirs
nbr_10day.plot.df <- ops_10day.df %>%
  dplyr::select(date_time, kitzmiller, barnum, 
                bloomington, barton, luke) %>%
  gather(key = "site", value = "flow", -date_time)
  
# Create North Br flows plot --------------------------------------------------
output$nbr_ten_day_plot <- renderPlot({
  ggplot(nbr_10day.plot.df, aes(x = date_time, y = flow)) + 
    geom_line(aes(colour = site))
})
  


