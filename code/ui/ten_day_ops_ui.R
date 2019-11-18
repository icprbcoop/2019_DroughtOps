# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Displays graphs and values on 10-Day Ops tab
# *****************************************************************************
# INPUTS
# *****************************************************************************
# Content created in code/server/ten_day_ops/ten_day_ops_server.R
# *****************************************************************************

tabPanel("10-Day Ops",
         fluidRow( # major row that contains whole body
           column( # major column that contains whole body
             width = 12,
             #
             # now add the content
             column(  # this is the 1st main column - with the graphs
               width = 6,
               fluidRow( # row with Little Falls flow graph
                 box(
                   title = "Little Falls flows - observed and forecasted",
                   width = NULL,
                   plotOutput("ten_day_plot", height = plot.height, width = plot.width)
                   # plotOutput("potomacFlows", height = "220px")
                 )
               ),
               fluidRow( # row with N Br flow graph
                 # h3("North Branch flows"),
                 column(
                   width = 12,
                   box(
                     title = "North Branch flows",
                     width = NULL,
                     plotOutput("nbr_ten_day_plot", height = "220px")
                   )
                 )
               ) # end of 2nd fluid row
             ), # end of 1st main column - with graphs
             column( # this is the 2nd main column - with values & triggers
               width = 6,
               # some general information
               valueBoxOutput("lfalls_today", width = NULL),
               valueBoxOutput("wma_withdr_9day_fc", width = NULL),
               valueBoxOutput("luke", width = NULL), 
               br(),
               box(title = "Jennings Randolph water supply release based on LFalls 9-day forecast from empirical recession equation",
                   width = NULL,
                   height=60),
               valueBoxOutput("lfalls_empirical_9day_fc", width = NULL),
               valueBoxOutput("empirical_9day_deficit", width = NULL),
               valueBoxOutput("luke_target1", width = NULL),
               br(),
               box(title = "Jennings Randolph water supply release based on LFalls 9-day forecast from LFFS",
                   width = NULL,
                   height=60),
               valueBoxOutput("lfalls_lffs_9day_fc", width = NULL),
               valueBoxOutput("lffs_9day_deficit", width = NULL),
               valueBoxOutput("luke_target2", width = NULL)
               # valueBoxOutput("lfalls_obs", width = NULL)
             ) # end of 2nd main column
           ) # end of major column that contains whole body
         ) # end of major row that contains whole body

) # end of tab panel