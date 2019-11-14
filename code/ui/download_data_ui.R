tabPanel("Download Data",
         fluidRow( # major row that contains whole body
           column( # major column that contains whole body
             width = 12,
             
             column(  # this is the 1st main column - with the buttons
               width = 6,
               
               actionButton("download_data_w",
                            "Download data",
                            icon = NULL,
                            width = "220px"),
               actionButton("view_data_w",
                            "Observe data",
                            icon = NULL,
                            width = "220px"),
               actionButton("accept_data_w",
                            "Accept and save the data",
                            icon = NULL,
                            width = "220px")
             ), #this is the end of the 1st main column
             
             column( # this is the 2nd main column - with the plotted data
               width = 6,
               
               fluidRow( # row with withdrawal data
                 box(
                   title = "Withdrawal data",
                   width = NULL,
                   plotOutput("withdrawal_plot", height = plot.height, width = plot.width)
                   
                 ) # box end
               ) # this is the end of row with withdrawal data
             ), # this is the end of 2nd main column
             
             column(  # this is the 3rd main column - with the buttons
               width = 6,
               
               actionButton("download_data_fd",
                            "Download data",
                            icon = NULL,
                            width = "220px"),
               actionButton("view_data_fd",
                            "Observe data",
                            icon = NULL,
                            width = "220px"),
               actionButton("accept_data_fd",
                            "Accept and save data",
                            icon = NULL,
                            width = "220px")
             ), #this is the end of the 3rd main column
             
             column( # this is the 4th main column - with the plotted data
               width = 6,
               
               fluidRow( # row with flows daily data
                 box(
                   title = "flows daily data",
                   width = NULL,
                   plotOutput("flows_daily_plot", height = plot.height, width = plot.width)
                   
                 ) # box end
               ) # this is the end of row with flows daily data
             ), # this is the end of 4th main column
             
             column(  # this is the 5th main column - with the buttons
               width = 6,
               
               actionButton("download_data_fh",
                            "Download data",
                            icon = NULL,
                            width = "220px"),
               actionButton("view_data_fh",
                            "Observe data",
                            icon = NULL,
                            width = "220px"),
               actionButton("accept_data_fh",
                            "Accept and save the data",
                            icon = NULL,
                            width = "220px")
             ), #this is the end of the 5th main column
               
             column( # this is the 6th main column - with the plotted data
               width = 6,
               fluidRow( # row with flows hourly data
                 box(
                   title = "flows hourly data",
                   width = NULL,
                   plotOutput("flows_hourly_plot", height = plot.height, width = plot.width)
                   
                 ) # box end
               ) # this is the end of row with flows hourly data
               
             ) # this is the end of 6th main column
             
             
           ) # end of major column that contains whole body
         ) # end of major row that contains whole body
)# end of tab panel