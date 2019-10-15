# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Create plots and values related to 10-day operations
# *****************************************************************************
# INPUTS
# *****************************************************************************
# flows_daily_cfs.csv - current daily streamflow data
# demands.daily.df - WMA supplier daily withdrawal data
# *****************************************************************************
# OUTPUTS
# *****************************************************************************
# All for display on 10-Day Ops page:
#   - output$ten_day_plot - graph of LFalls observed & forecasted flows
#   - output$nbr_ten_day_plot - graph of NBr res. inflows & outflows; & Luke
#   - output$lfalls_empirical_9day_fc - LFalls forecast from our empirical eq.
#   - output$9_day_deficit - estimated need at LFalls 9 days hence, MGD
#   - output$9_day_luke_target, cfs
# *****************************************************************************

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Construct time series
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Need to work on "today" - right now this will do here -----------------------
date_today_ops <- as.Date(today())
# date_today_ops <- round.POSIXt(date_today_ops, units = "days")

# Create 10-day df with all needed data  --------------------------------------
ops_10day.df <- left_join(flows.daily.mgd.df, 
                          demands.daily.df, by = "date_time") %>%
  dplyr::select(date_time, lfalls, luke, kitzmiller, barnum,
                bloomington, barton, d_total)

# Prepare data for LFalls flow plot, incl. fc's -------------------------------
#   - 9-day forecast from coop empirical eq.
#   - constant 9-day lag from reservoirs to LFalls for now
date_time_9dayshence = date_today_ops + 9                                   
ops_10day.df <- ops_10day.df %>%
  dplyr::mutate(res_inflow = kitzmiller + barton,
                res_outflow = barnum + bloomington,
                res_augmentation = res_outflow - res_inflow,
                res_aug_lagged8 = lag(res_augmentation, 8),
                res_aug_lagged9 = lag(res_augmentation, 9),
                res_aug_lagged10 = lag(res_augmentation, 10),
                res_aug_lagged = (res_aug_lagged8 + res_aug_lagged9
                                  + res_aug_lagged10)/3,
                lfalls_nat = lfalls + d_total - res_aug_lagged,
                lfalls_nat_empirical_fc = 288.79*exp(0.0009*lfalls_nat),
                lfalls_nat_empirical_fc = case_when(
                  lfalls_nat_empirical_fc > lfalls_nat ~ lfalls_nat,
                  lfalls_nat_empirical_fc <= lfalls_nat 
                  ~ lfalls_nat_empirical_fc,
                  TRUE ~ -9999),
                lfalls_nat_empirical_fc = lag(lfalls_nat_empirical_fc, 9),
                # compute lfalls obs by subtracting WMA demand & adding back 
                #    reservoir augmentation
                lfalls_empirical_fc = lfalls_nat_empirical_fc - 
                  d_total + res_aug_lagged9
                ) %>%
  dplyr::filter(date_time < date_today_ops + 20) %>%
  dplyr::filter(date_time > date_today_ops - 12)

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Construct graphs
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Prepare for plotting LFalls flows - first graph on ui -----------------------
lfalls_10day.plot.df <- ops_10day.df %>%
  dplyr::select(date_time, lfalls, d_total) %>%
  gather(key = "site", value = "flow", -date_time)

# There must be a better way to plot the fc point -----------------------------
lfalls_10day.plot2.df <- ops_10day.df %>%
  dplyr::select(date_time, lfalls_empirical_fc) %>%
  gather(key = "site", value = "flow", -date_time) %>%
  filter(date_time == date_time_9dayshence & site == "lfalls_empirical_fc")

# Create LFalls flow plot -----------------------------------------------------
output$ten_day_plot <- renderPlot({
  ggplot(lfalls_10day.plot.df, aes(x = date_time, y = flow)) + 
    geom_line(aes(colour = site, size = site)) +
    scale_color_manual(values = c("red", "deepskyblue1", "blue")) +
    scale_size_manual(values = c(1, 2, 1)) +
    # shape=1 is open circle, stroke is border width
    geom_point(data = lfalls_10day.plot2.df, aes(x = date_time, y = flow),
               size = 5, colour = "blue", shape = 1, stroke = 1.5)

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
  
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Construct value box content
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Grab LFalls 9-day fc value for display --------------------------------------
lfalls_9day_fc_mgd <- round(lfalls_10day.plot2.df$flow[1], 0)
lfalls_9day_fc_cfs <- round(lfalls_9day_fc_mgd*mgd_to_cfs, 0)
output$lfalls_empirical_9day_fc <- renderValueBox({
  lfalls_9day_fc <- paste(
    "Forecasted flow at Little Falls in 9 days (from empirical eq.): ",
                          lfalls_9day_fc_mgd, " MGD (", 
                          lfalls_9day_fc_cfs, " cfs)",
                          sep = "")
  valueBox(
    value = tags$p(lfalls_9day_fc, style = "font-size: 50%;"),
    subtitle = NULL,
    color = "blue"
  )
})

# Grab total WMA withdrawal 9-day fc for display -----------------------------
wma_withdr_fc <- ops_10day.df %>%
  filter(date_time == date_today_ops + 9)
wma_withdr_fc <- round(wma_withdr_fc$d_total[1], 0)
output$wma_withdr_9day_fc <- renderValueBox({
  wma_withdr <- paste(
    "Forecasted WMA total withdrawals in 9 days (from COOP regression eqs.): ",
                          wma_withdr_fc,
                          " MGD", sep = "")
  valueBox(
    value = tags$p(wma_withdr, style = "font-size: 50%;"),
    subtitle = NULL,
    color = "orange"
  )
})

# Display today's flow at Luke ------------------------------------------------
luke_flow_today <- ops_10day.df %>%
  filter(date_time == date_today_ops)
luke_mgd <- round(luke_flow_today$luke[1], 0)
luke_cfs <- round(luke_mgd*mgd_to_cfs, 0)
output$luke <- renderValueBox({
  luke_today <- paste("Flow at Luke today: ",
                      luke_mgd,
                      " MGD (", 
                      luke_cfs, 
                      " cfs)", sep = "")
  valueBox(
    value = tags$p(luke_today, style = "font-size: 50%;"),
    subtitle = NULL,
    color = "light-blue"
  )
})
