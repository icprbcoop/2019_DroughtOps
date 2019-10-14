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
date_today_ops <- as.POSIXct(today())
ops_10day.df <- left_join(flows.daily.mgd.df, demands.daily.df) %>%
  # dplyr::filter(date_time < date_today_ops - 20) %>%
  # dplyr::filter(date_time > date_today_ops + 12) %>%
  dplyr::select(date_time, lfalls, luke, kitzmiller, barnum, 
                bloomington, barton, d_total)
ops_10day.plot.df <- ops_10day.df %>%
  gather(key = "site", value = "flow", -date_time)

output$ten_day_plot <- renderPlot({
  
  # ops_10day.plot.df$date_time <- as_datetime(as.character(ten_day.df$date_time))
  
  ggplot(ops_10day.plot.df, aes(x = date_time, y = flow)) + 
    geom_line(aes(colour = site))
  
})

