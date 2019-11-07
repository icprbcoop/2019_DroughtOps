# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Create graphs and values displayed for 1-day operations
# *****************************************************************************
# INPUTS
# *****************************************************************************
# flows_hourly_cfs.csv - current daily streamflow data in cfs
# withdr.hourly.df - WMA supplier hourly withdrawal data
#                  - past 30 days and future 14 days
# *****************************************************************************
# OUTPUTS
# *****************************************************************************
# flows_hourly_mgd.csv- current daily streamflow data in mgd
#
# For display on 1-Day Ops page
#   Plots:
#   - output$one_day_ops_plot - graph of LFalls observed & forecasted flows
#   Value boxes:
#   - output$lfalls_1day_fc - LFalls forecast
#   - output$wma_withdr_1day_fc - WMA Potomac withdrawal 1-day forecast
#   - output$1day_deficit - estimated need at LFalls tomorrow
# *****************************************************************************

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Prepare 1-day LFalls fc, constant lags, daily data
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

ops_1day_daily.df <- flows.daily.mgd.df %>%
  dplyr::select(date_time, lfalls, seneca, goose, 
                monoc_jug, por, d_pot_total) %>%
  dplyr::mutate(lfalls_predicted_constant_lags = 
                  lag(seneca, 1) + lag(goose, 1) + 
                  lag(monoc_jug, 1) + lag(por, 1) -
                  d_pot_total)

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Prepare 1-day LFalls fc, flow-dependent lags, hourly data
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Convert flows to mgd --------------------------------------------------------
func_cfs_to_mgd <- function(cfs) {round(cfs/mgd_to_cfs,0)}
flows.hourly.mgd.df <- flows.hourly.cfs.df %>%
  dplyr::mutate_at(2:32, func_cfs_to_mgd)

# Select the gages of interest ------------------------------------------------
ops_1day.df <- flows.hourly.mgd.df %>%
  select(date_time, lfalls, seneca, goose, monoc_jug, por)

# Fill in missing data --------------------------------------------------------
#   - delete last row to avoid missing data which messes up na.approx
ops_1day.df <- head(ops_1day.df, -1)
ops_1day.df$lfalls <- na.approx(ops_1day.df$lfalls)
ops_1day.df$seneca <- na.approx(ops_1day.df$seneca)
ops_1day.df$goose <- na.approx(ops_1day.df$goose)
ops_1day.df$monoc_jug <- na.approx(ops_1day.df$monoc_jug)
ops_1day.df$por <- na.approx(ops_1day.df$por)

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Construct graphs
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# LFall predicted from constant lags - first graph on ui ----------------------
lfalls_1day.plot1.df <- ops_1day_daily.df %>%
  mutate(lfalls_flowby = lfalls_flowby) %>%
  select(-d_pot_total) %>%
  gather(key = "site", value = "flow", -date_time)

output$one_day_ops_plot1 <- renderPlot({
  lfalls_1day.plot1.df <- lfalls_1day.plot1.df %>%
  filter(date_time >= input$plot_range[1],
         date_time <= input$plot_range[2]) 
  ggplot(lfalls_1day.plot1.df, aes(x = date_time, y = flow)) + 
    geom_line(aes(colour = site, size = site, linetype = site)) +
    scale_color_manual(values = c("steelblue","deepskyblue1", "red",
                                  "deepskyblue3", "plum", 
                                  "palegreen3", "slateblue1")) +
    scale_linetype_manual(values = c("solid", "solid", "dashed",
                                     "dashed", "solid",
                                     "solid","solid")) +
    scale_size_manual(values = c(1, 2, 1, 1, 1, 1, 1))

})
  

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Construct value box content
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

date_time_1dayhence = date_today0 + 1

# LFalls 1-day fc - constant lags ---------------------------------------------
lfalls_1day_fc1_mgd <- ops_1day_daily.df %>%
  filter(date_time == date_time_1dayhence)
lfalls_1day_fc1_mgd <- round(
  lfalls_1day_fc1_mgd$lfalls_predicted_constant_lags[1], 0)
lfalls_1day_fc1_cfs <- round(lfalls_1day_fc1_mgd*mgd_to_cfs, 0)
output$lfalls_fc1 <- renderValueBox({
  lfalls_1day_fc <- paste(
    "Forecasted flow at Little Falls in 1 day (constant lags): ",
                          lfalls_1day_fc1_mgd, " MGD (",
                          lfalls_1day_fc1_cfs, " cfs)",
                          sep = "")
  valueBox(
    value = tags$p(lfalls_1day_fc, style = "font-size: 50%;"),
    subtitle = NULL,
    color = "light-blue"
  )
})

# Little Falls 1-day deficit - constant lags ----------------------------------
lfalls_1day_deficit1_mgd <- estimate_need_func(
  lfalls_flow = lfalls_1day_fc1_mgd,
  mos = 120
)
lfalls_1day_deficit1_cfs <- round(lfalls_1day_deficit1_mgd*mgd_to_cfs, 0)

output$lfalls_deficit1 <- renderValueBox({
  lfalls_1day_def <- paste(
    "Forecasted deficit at Little Falls in 1 day (constant lags): ",
    lfalls_1day_deficit1_mgd, " MGD (",
    lfalls_1day_deficit1_cfs, " cfs)",
    sep = "")
  valueBox(
    value = tags$p(lfalls_1day_def, style = "font-size: 50%;"),
    subtitle = NULL,
    # LukeV: change color to orange if value > 0
    color = "light-blue"
  )
})
# 
# # Grab total WMA withdrawal 9-day fc for display -----------------------------
# wma_withdr_fc <- ops_10day.df %>%
#   filter(date_time == date_today_ops + 9)
# wma_withdr_fc <- round(wma_withdr_fc$d_pot_total[1], 0)
# output$wma_withdr_9day_fc <- renderValueBox({
#   wma_withdr <- paste(
#     "Forecasted WMA total withdrawals in 9 days (from COOP regression eqs.): ",
#                           wma_withdr_fc,
#                           " MGD", sep = "")
#   valueBox(
#     value = tags$p(wma_withdr, style = "font-size: 50%;"),
#     subtitle = NULL,
#     color = "light-blue"
#   )
# })
# 
# # Display today's flow at Luke ------------------------------------------------
# luke_flow_today <- ops_10day.df %>%
#   filter(date_time == date_today_ops)
# luke_mgd <- round(luke_flow_today$luke[1], 0)
# luke_cfs <- round(luke_mgd*mgd_to_cfs, 0)
# output$luke <- renderValueBox({
#   luke_today <- paste("Flow at Luke today 
#                       before water supply release request: ",
#                       luke_mgd,
#                       " MGD (", 
#                       luke_cfs, 
#                       " cfs)", sep = "")
#   valueBox(
#     value = tags$p(luke_today, style = "font-size: 50%;"),
#     subtitle = NULL,
#     color = "light-blue"
#   )
# })
# 
# # Display deficit in nine days time
# deficit_mgd <- round(lfalls_flowby - lfalls_9day_fc_mgd, 0)
# deficit_cfs <- round(deficit_mgd*mgd_to_cfs)
# output$deficit <- renderValueBox({
#   deficit_9days <- paste("Flow deficit in 9 days time: ",
#                          deficit_mgd,
#                       " MGD (", 
#                       deficit_cfs, 
#                       " cfs) [Negative deficit is a surplus]", sep = "")
#   valueBox(
#     value = tags$p(deficit_9days, style = "font-size: 50%;"),
#     subtitle = NULL,
#     # LukeV - want orange if deficit_mgd is positive, light-blue if negative
#     color = "light-blue"
#   )
# })
# 
# # Display today's Luke target
# luke_extra <- if_else(deficit_mgd <= 0, 0, deficit_mgd)
# luke_target_mgd <- round(luke_mgd + luke_extra, 0)
# luke_target_cfs <- round(luke_target_mgd*mgd_to_cfs, 0)
# output$luke_target <- renderValueBox({
#   luke_target <- paste("Today's Luke target: ",
#                        luke_target_mgd,
#                          " MGD (", 
#                        luke_target_cfs, 
#                          " cfs)", sep = "")
#   valueBox(
#     value = tags$p(luke_target, style = "font-size: 50%;"),
#     subtitle = NULL,
#     # LukeV - want orange if luke_extra > 0, light-blue if 0
#     color = "light-blue"
#   )
# })