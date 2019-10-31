output$demands <- renderPlot({
  
  # plot total FW demand
  demands.plot.df <- demands.daily.df %>%
    mutate(d_fw_pot = d_fw_w, d_wssc_pot = d_wssc) %>%
    select(date_time, d_fw_pot, d_wssc_pot, d_wa, d_lw)
  
  # gather the data into long format; use the dynamic plot ranges
  demands.df <- gather(demands.plot.df, key = "location", 
                       value = "flow", -date_time) %>%
    mutate(Date = date_time) %>%
    filter(Date >= input$plot_range[1],
           Date <= input$plot_range[2])
  
  # plot the data
  ggplot(demands.df, aes(x = date_time, y = flow)) + 
    geom_line(aes(colour = location))
  
})
