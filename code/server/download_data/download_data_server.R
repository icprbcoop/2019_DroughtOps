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
  write.csv(demands.df, paste(ts_path, "download_data_w_temp.csv"))
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
  
  #construct path for daily flows data
  first_of_year = as.Date("2019-1-1")
  
  daily_start = paste0(format(first_of_year,"%m"),"%2F",format(first_of_year,"%d"), "%2F",format(first_of_year,"20%y"))
  print(daily_start)
  
  daily_end = paste0(format(date_today0,"%m"),"%2F",format(date_today0,"%d"), "%2F",format(date_today0,"20%y"))
  
  full_daily_url = paste0("http://icprbcoop.org/drupal4/icprb/flow-data?","startdate=", daily_start,"&enddate=" ,daily_end, "&format=daily&submit=Submit")
  
  print(full_daily_url)
  
  #-----------------------------
  #import the data from sarah's site
  demands_raw.df <- data.table::fread(full_daily_url,
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
  
  date_minus_five = date_today0 - 5
  hourly_start = paste0(format(date_minus_five,"%m"),"%2F",format(date_minus_five,"%d"), "%2F",format(date_minus_five,"20%y"))
  
  hourly_end = paste0(format(date_today0,"%m"),"%2F",format(date_today0,"%d"), "%2F",format(date_today0,"20%y"))
  
  full_hourly_url = paste0("http://icprbcoop.org/drupal4/icprb/flow-data?","startdate=", hourly_start,"&enddate=" ,hourly_end, "&format=hourly&submit=Submit")
  
  #http://icprbcoop.org/drupal4/icprb/flow-data?startdate=11%2f3%2f2019&enddate=11%2f8%2f2019&format=hourly&submit=Submit
  
  #import the hourly flows data from sarah's site
  demands_raw.df <- data.table::fread(full_hourly_url,
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

################# need code to append new data to old data
######requires a join to existing data

#write dataframe to file
write.csv(demands.df, paste(ts_path, "flows_hourly_cfs.csv"))#"download_data_fh.csv"))
})

