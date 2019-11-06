# tabPanel("One Day"
# 
# ) # end of tab panel

tabPanel("1-Day Ops",
         fluidRow( # major row that contains whole body
           column( # major column that contains whole body
             width = 12,
             #
             # now add the content
             column(  # this is the 1st main column - with the graphs
               width = 6,
               fluidRow( # row with Potomac flow graph
                 box(
                   title = "Little Falls predicted from upstream gages 
                   - constant lags",
                   width = NULL,
                   plotOutput("one_day_ops_plot1", height = "280px")
                 )
               ),
               fluidRow( # row with optional other graphs
                 h3("Placeholder space for optional other graphs"),
                 column(
                   width = 12,
                   box(
                     title = "Maybe want another graph",
                     width = NULL
                     # plotOutput("one_day_plot", height = "150px")
                   )
                 )
               ) # end of 2nd fluid row
               ), # end of 1st main column - with graphs
             column( # this is the 2nd main column - with values & triggers
               width = 6, 
               valueBoxOutput("lfalls_fc1", width = NULL),
               valueBoxOutput("lfalls_deficit1", width = NULL)
               ) # end of 2nd main column
           ) # end of major column that contains whole body
         ) # end of major row that contains whole body

) # end of tab panel