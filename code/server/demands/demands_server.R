# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Create graphs and values displayed for 10-day operations
# *****************************************************************************
# INPUTS
# *****************************************************************************
# flows_daily_cfs.csv - current daily streamflow data
# demands.daily.df - WMA supplier daily withdrawal data
# *****************************************************************************
# OUTPUTS
# *****************************************************************************
# All for display on 10-Day Ops page
#   Plots:
#   - output$ten_day_plot - graph of LFalls observed & forecasted flows
#   - output$nbr_ten_day_plot - graph of NBr res. inflows & outflows; & Luke
#   Value boxes:
#   - output$lfalls_empirical_9day_fc - LFalls forecast from our empirical eq.
#   - output$wma_withdr_9day_fc - WMA Potomac withdrawal 9-day forecast
#   - output$luke - today's flow at Luke before water supply release request
#   - output$deficit - estimated need at LFalls 9 days hence
#   - output$luke_target - today's target
# *****************************************************************************

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Grab daily time series
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Select values to plot
demands.plot.df <- demands.daily.df %>%
  mutate(d_fw_pot = d_fw_w, d_wssc_pot = d_wssc, d_lw_pot = d_lw) %>%
  # select(date_time, d_fw_pot, d_wssc_pot, wa_gf, wa_lf, d_lw_pot)
  select(date_time, d_fw_pot, d_wssc_pot, d_wa, d_lw_pot)

# Grab yesterday's values to display
demands_yesterday.df <- demands.plot.df %>%
  filter(date_time == date_today0 - 1)

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Construct graphs
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
output$demands <- renderPlot({
  # gather the data into long format; use the dynamic plot ranges
  demands.df <- gather(demands.plot.df, key = "location", 
                       value = "flow", -date_time) %>%
    mutate(Date = date_time) %>%
    filter(Date >= input$plot_range[1],
           Date <= input$plot_range[2])
  
  # plot the data
  ggplot(demands.df, aes(x = date_time, y = flow)) + 
    geom_line(aes(colour = location)) +
    labs(x = "", y = "Potomac withdrawals, MGD")
})

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Construct value box content
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Display yesterday's Potomac withdrawals -------------------------------------
output$w_pot_fw_yesterday <- renderValueBox({
  w_fw_yesterday <- paste(
    "Yesterday's Fairfax Water withdrawal: ",
    demands_yesterday.df$d_fw_pot[1],
    " MGD", sep = "")
  valueBox(
    value = tags$p(w_fw_yesterday, style = "font-size: 50%;"),
    subtitle = NULL,
    color = "light-blue"
  )
})

output$w_pot_wssc_yesterday <- renderValueBox({
  w_wssc_yesterday <- paste(
    "Yesterday's WSSC withdrawal: ",
    demands_yesterday.df$d_wssc_pot[1],
    " MGD", sep = "")
  valueBox(
    value = tags$p(w_wssc_yesterday, style = "font-size: 50%;"),
    subtitle = NULL,
    color = "light-blue"
  )
})

output$w_pot_gf_yesterday <- renderValueBox({
  w_gf_yesterday <- paste(
    "Yesterday's Washington Aqueduct Great Falls withdrawal: ",
    demands_yesterday.df$wa_gf[1],
    " MGD", sep = "")
  valueBox(
    value = tags$p(w_gf_yesterday, style = "font-size: 50%;"),
    subtitle = NULL,
    color = "light-blue"
  )
})

output$w_pot_lf_yesterday <- renderValueBox({
  w_lf_yesterday <- paste(
    "Yesterday's Washington Aqueduct Little Falls withdrawal: ",
    demands_yesterday.df$wa_lf[1],
    " MGD", sep = "")
  valueBox(
    value = tags$p(w_lf_yesterday, style = "font-size: 50%;"),
    subtitle = NULL,
    color = "light-blue"
  )
})

output$w_pot_lw_yesterday <- renderValueBox({
  w_lw_yesterday <- paste(
    "Yesterday's Loudoun Water withdrawal: ",
    demands_yesterday.df$d_lw_pot[1],
    " MGD", sep = "")
  valueBox(
    value = tags$p(w_lw_yesterday, style = "font-size: 50%;"),
    subtitle = NULL,
    color = "light-blue"
  )
})

