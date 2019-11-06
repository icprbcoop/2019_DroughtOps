# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Create graphs, values, and displays on situational awareness tab
# *****************************************************************************
# INPUTS
# *****************************************************************************
# flows.daily.mgd.df - df with daily streamflow data & Potomac withdrawals
# *****************************************************************************
# OUTPUTS
# *****************************************************************************
# All for display on Situational Awareness page
#   Plots:
#   - output$sit_aware_plot - various obs. flows & recession estimates
#   - output$jrr_plot
#   - output$occ_plot
#   - output$sen_plot
#   - output$pat_plot
#   Value boxes:
#   - output$lfalls_empirical_9day_fc - LFalls forecast from our empirical eq.
#   - output$wma_withdr_9day_fc - WMA Potomac withdrawal 9-day forecast
#   - output$luke - today's flow at Luke before water supply release request
#   - output$deficit - estimated need at LFalls 9 days hence
#   - output$luke_target - today's target
# *****************************************************************************

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Construct graphs
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Select flows of interest ----------------------------------------------------
sit_aware_mgd.df <- flows.daily.mgd.df %>%
  dplyr::select(date_time, lfalls, por, monoc_jug, shen_mill,
                seneca, d_pot_total) %>%
  dplyr::mutate(lfalls_flowby = lfalls_flowby,
                por_trigger = 2000)

flows.plot.df <- sit_aware_mgd.df %>%
  gather(key = "site", value = "flow", -date_time)

output$flows_plot <- renderPlot({
  flows.plot.df <- flows.plot.df %>%  
  filter(date_time >= input$plot_range[1],
         date_time <= input$plot_range[2])
  ggplot(flows.plot.df, aes(x = date_time, y = flow)) + 
    geom_line(aes(colour = site, size = site, linetype = site)) +
    scale_color_manual(values = c("orange", "deepskyblue1", "red", 
                                  "steelblue3", "blue",
                                  "tomato1", "slategray3", "plum")) +
    scale_size_manual(values = c(1, 2, 1, 1, 1, 1, 1, 1)) +
    scale_linetype_manual(values = c("solid", "solid", "dashed",
                                     "solid", "solid",
                                     "dotted","solid","solid"))
})
  
