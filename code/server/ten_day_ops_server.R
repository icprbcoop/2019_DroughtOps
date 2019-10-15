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
# Need to work on "today" - right now this will do -----------------
date_today_ops <- as.Date(today())
# date_today_ops <- round.POSIXt(date_today_ops, units = "days")

# Create 10-day df with all the data of interest ------------------------------
ops_10day.df <- left_join(flows.daily.mgd.df, 
                          demands.daily.df, by = "date_time") %>%
  dplyr::select(date_time, lfalls, luke, kitzmiller, barnum,
                bloomington, barton, d_total)

# Prepare data for LFalls flow plot, incl. fc's -------------------------------
#   - forecast from coop empirical eq. same as old spreadsheet for now
#   - constant 9-day lag from reservoirs to LFalls for now
# date_time_9dayshence <- date_today_ops + lubridate::days(9) 
# date_time_9dayshence <- round_date(date_time_9dayshence, units = "days")
                                   
ops_10day.df <- ops_10day.df %>%
  dplyr::mutate(res_inflow = kitzmiller + barton,
                res_outflow = barnum + bloomington,
                res_augmentation = res_outflow - res_inflow,
                res_aug_lagged8 = lag(res_augmentation, 8),
                res_aug_lagged9 = lag(res_augmentation, 9),
                res_aug_lagged10 = lag(res_augmentation, 10),
                res_aug_lagged = (res_aug_lagged8 + res_aug_lagged9
                                  + res_aug_lagged10)/3,
                date_time_9dayshence = date_today_ops + 9,
                # date_time_9dayshence <- round_date(date_time_9dayshence, 
                #                                    units = "days"),
                lfalls_nat = lfalls + d_total - res_aug_lagged,
                lfalls_nat_empirical_fc = 288.79*exp(0.0009*lfalls_nat),
                lfalls_nat_empirical_fc = case_when(
                  lfalls_nat_empirical_fc > lfalls_nat ~ lfalls_nat,
                  lfalls_nat_empirical_fc <= lfalls_nat 
                  ~ lfalls_nat_empirical_fc,
                  TRUE ~ -9999),
                lfalls_nat_empirical_fcp = lag(lfalls_nat_empirical_fc, 9),
                lfalls_nat_empirical_fcp = ifelse(
                  date_time == date_time_9dayshence, lfalls_nat_empirical_fcp, NA)
                ) %>%
  dplyr::filter(date_time < date_today_ops + 20) %>%
  dplyr::filter(date_time > date_today_ops - 12)

lfalls_10day.plot.df <- ops_10day.df %>%
  dplyr::select(date_time, lfalls, lfalls_nat_empirical_fcp, d_total) %>%
  gather(key = "site", value = "flow", -date_time)


# Create LFalls flow plot -----------------------------------------------------
output$ten_day_plot <- renderPlot({
  ggplot(lfalls_10day.plot.df, aes(x = date_time, y = flow)) + 
    geom_line(aes(colour = site, size = site)) +
    scale_color_manual(values = c("red", "deepskyblue1", "blue")) +
    scale_size_manual(values = c(1, 2, 1))

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
  


