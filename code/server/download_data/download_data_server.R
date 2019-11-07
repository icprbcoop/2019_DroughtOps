# download data from withdrawal_data
observeEvent(input$download_data_w, {
  #import the data from sarah's site
  demands_raw.df <- data.table::fread("http://icprbcoop.org/drupal4/products/coop_pot_withdrawals.csv",
                                      data.table = FALSE)
  
  #gather the data into long format
  demands.df <- gather(demands_raw.df,site, flow, 2:6)
  
  # #turn dates to date_time type
  # demands.df$DateTime <- as_datetime(as.character(demands.df$DateTime))
  
  #write dataframe to file
  write.csv(demands.df, paste(ts_path, "download_w_data_temp.csv"))
})

observeEvent(input$view_data_w, {
  
  #read file
  demands.df <- data.table::fread(paste(ts_path, "download_data_w_temp.csv"),
                                  data.table = FALSE)
  
  #turn dates to date_time type
  demands.df$DateTime <- as_datetime(as.character(demands.df$DateTime))
  
  #plot the data
  #button interaction needs to be conditional on data being readable in directory
  output$withdrawal_plot <- renderPlot({ ggplot(demands.df, aes(x = DateTime, y = flow)) + geom_line(aes(linetype = site, colour = site))
    
  })
})

observeEvent(input$accept_data_w, {

#read file
demands.df <- data.table::fread(paste(ts_path, "download_data_w_temp.csv"),
                                data.table = FALSE)
#write dataframe to file
write.csv(demands.df, paste(ts_path, "coop_pot_withdrawals.csv"))
})






#download data from flows daily

observeEvent(input$download_data_fd, {
  #import the data from sarah's site
  demands_raw.df <- data.table::fread("http://icprbcoop.org/drupal4/products/coop_pot_withdrawals.csv",
                                      data.table = FALSE)
  
  #gather the data into long format
  demands.df <- gather(demands_raw.df,site, flow, 2:6)
  
  # #turn dates to date_time type
  # demands.df$DateTime <- as_datetime(as.character(demands.df$DateTime))
  
  #write dataframe to file
  write.csv(demands.df, paste(ts_path, "download_data_fd_temp.csv"))
})

observeEvent(input$view_data_fd, {
  
  #read file
  demands.df <- data.table::fread(paste(ts_path, "download_data_fd_temp.csv"),
                                  data.table = FALSE)
  
  #turn dates to date_time type
  demands.df$DateTime <- as_datetime(as.character(demands.df$DateTime))
  
  #plot the data
  #button interaction needs to be conditional on data being readable in directory
  output$withdrawal_plot <- renderPlot({ ggplot(demands.df, aes(x = DateTime, y = flow)) + geom_line(aes(linetype = site, colour = site))
    
  })
})

observeEvent(input$accept_data_fd, {

#read file
demands.df <- data.table::fread(paste(ts_path, "download_data_fd_temp.csv"),
                                data.table = FALSE)
#write dataframe to file
write.csv(demands.df, paste(ts_path, "flows_daily_cfs.csv"))#"download_data_fd.csv"))
})






#download data flows hourly

observeEvent(input$download_data_fh, {
  #construct file path
  
  #https://icprbcoop.org/drupal4/icprb/flow-data?startdate=11%2F2%2F2019&enddate=11%2F07%2F2019&format=hourly&submit=Submit
  #paste("https://icprbcoop.org/drupal4/icprb/flow-data?", start, end, "&format=hourly&submit=Submit")
  
  #import the data from sarah's site
  demands_raw.df <- data.table::fread("http://icprbcoop.org/drupal4/products/coop_pot_withdrawals.csv",
                                      data.table = FALSE)
  
  #gather the data into long format
  demands.df <- gather(demands_raw.df,site, flow, 2:6)
  
  # #turn dates to date_time type
  # demands.df$DateTime <- as_datetime(as.character(demands.df$DateTime))
  
  #write dataframe to file
  write.csv(demands.df, paste(ts_path, "download_data_fh_temp.csv"))
})

observeEvent(input$view_data_fh, {
  
  #read file
  demands.df <- data.table::fread(paste(ts_path, "download_data_fh_temp.csv"),
                                  data.table = FALSE)
  
  #turn dates to date_time type
  demands.df$DateTime <- as_datetime(as.character(demands.df$DateTime))
  
  
  
  #plot the data
  #button interaction needs to be conditional on data being readable in directory
  output$withdrawal_plot <- renderPlot({ ggplot(demands.df, aes(x = DateTime, y = flow)) + geom_line(aes(linetype = site, colour = site))
    
  })
})

observeEvent(input$accept_data_fh, {
#read file
demands.df <- data.table::fread(paste(ts_path, "download_data_fh_temp.csv"),
                                data.table = FALSE)

######requires a join to existing data

#write dataframe to file
write.csv(demands.df, paste(ts_path, "flows_hourly_cfs.csv"))#"download_data_fh.csv"))
})

