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
#   - plot will be cfs
sit_aware_cfs.df <- flows.daily.mgd.df %>%
  dplyr::select(date_time, lfalls, por, monoc_jug, shen_mill,
                seneca, d_pot_total) %>%
  dplyr::mutate(lfalls = lfalls*mgd_to_cfs, por = por*mgd_to_cfs,
                monoc_jug = monoc_jug*mgd_to_cfs, 
                shen_mill = shen_mill*mgd_to_cfs, seneca = seneca*mgd_to_cfs,
                d_pot_total = d_pot_total*mgd_to_cfs,
                lfalls_flowby = lfalls_flowby*mgd_to_cfs,
                por_trigger = 2000)

flows.plot.df <- sit_aware_cfs.df %>%
  gather(key = "site", value = "flow", -date_time)

output$sit_aware_flows_plot <- renderPlot({
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
                                     "dotted","solid","solid")) +
    labs(x = "", y = "Flow, cfs")
})

#------------------------------------------------------------------
# Create graph of storage and releases for each reservoir
#------------------------------------------------------------------
output$sit_aware_jrr_stor <- renderPlot({
  graph_title <- "Jennings Randolph"
  jrr.graph <- ts$jrr %>%
    select(Date = date_time,
           "WS stor" = storage_ws,
           "WQ stor" = storage_wq
           ,
           "WS rel" = outflow_ws,
           "WQ rel" = outflow_wq
    ) %>%
    gather(key = "Legend",
           value = "MG", -Date) %>%
    filter(Date >= input$plot_range[1],
           Date <= input$plot_range[2])
  ggplot(data = jrr.graph,
         aes(x = Date, y = MG, group = Legend)) +
    geom_line(aes(color = Legend, size = Legend)) +
    scale_color_manual(values = c("lightgreen", "green",
                                  "lightblue", "blue")) +
    scale_size_manual(values = c(0.5, 1, 0.5, 1)) +
    ggtitle(graph_title) +
    theme(plot.title = element_text(size = 18)) +
    # face = "bold")) +
    theme(axis.title.x = element_blank(),
          axis.title.y = element_blank()) +
    theme(legend.position = "right",
          legend.title = element_blank())
}) # end jrr renderPlot testing
#
#------------------------------------------------------------------
# I can't get the following graphing function to work:
# output$senStorageReleases <- renderPlot({
#   sen.graph <- ts$sen
#   graph_title <- "Seneca"
#   display_graph_res_func(graph_title, sen.graph)
# })
output$sit_aware_sen_stor <- renderPlot({
  sen.graph <- ts$sen
  graph_title <- "Little Seneca"
  res.graph <- sen.graph %>%
    select(date_time, storage, outflow) %>%
    gather(key = "Legend",
           value = "MG", -date_time) %>%
    filter(date_time >= input$plot_range[1],
           date_time <= input$plot_range[2])
  ggplot(data = res.graph,
         aes(x = date_time, y = MG, group = Legend)) +
    geom_line(aes(color = Legend, size = Legend)) +
    scale_color_manual(values = c("lightblue",
                                  "blue")) +
    scale_size_manual(values = c(0.5, 1)) +
    ggtitle(graph_title) +
    theme(plot.title = element_text(size = 18)) +
    theme(axis.title.x = element_blank(),
          axis.title.y = element_blank()) +
    theme(legend.position = "none")
}) # end sen renderPlot
#
#------------------------------------------------------------------
output$sit_aware_pat_stor <- renderPlot({
  pat.graph <- ts$pat
  graph_title <- "Patuxent"
  res.graph <- pat.graph %>%
    select(date_time, storage, outflow) %>%
    gather(key = "Legend",
           value = "MG", -date_time) %>%
    filter(date_time >= input$plot_range[1],
           date_time <= input$plot_range[2])
  ggplot(data = res.graph,
         aes(x = date_time, y = MG, group = Legend)) +
    geom_line(aes(color = Legend, size = Legend)) +
    scale_color_manual(values = c("lightblue",
                                  "blue")) +
    scale_size_manual(values = c(0.5, 1)) +
    ggtitle(graph_title) +
    theme(plot.title = element_text(size = 18)) +
    theme(axis.title.x = element_blank(),
          axis.title.y = element_blank()) +
    theme(legend.position = "none")
}) # end pat renderPlot
#
#------------------------------------------------------------------
output$sit_aware_occ_stor <- renderPlot({
  occ.graph <- ts$occ
  graph_title <- "Occoquan"
  res.graph <- occ.graph %>%
    select(date_time, storage, outflow) %>%
    gather(key = "Legend",
           value = "MG", -date_time) %>%
    filter(date_time >= input$plot_range[1],
           date_time <= input$plot_range[2])
  ggplot(data = res.graph,
         aes(x = date_time, y = MG, group = Legend)) +
    geom_line(aes(color = Legend, size = Legend)) +
    scale_color_manual(values = c("lightblue",
                                  "blue")) +
    scale_size_manual(values = c(0.5, 1)) +
    ggtitle(graph_title) +
    theme(plot.title = element_text(size = 18)) +
    theme(axis.title.x = element_blank(),
          axis.title.y = element_blank()) +
    theme(legend.position = "none")
}) # end occ renderPlot

  
