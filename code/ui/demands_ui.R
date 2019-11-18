# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Displays graphs and values on Demand tab
# *****************************************************************************
# INPUTS
# *****************************************************************************
# Content created in code/server/demands/demands_server.R
# *****************************************************************************

# tabPanel("Demands",
#          fluidRow( # major row that contains whole body
#            align = "center",
#            plotOutput("demands", height = plot.height, width = plot.width),
#            br()
#          ) # End fluidRow 
# ) # end of tab panel

tabPanel("Demands",
fluidRow( # major row that contains whole body
  column( # major column that contains whole body
    width = 12,
    #
    # now add the content
    column(  # this is the 1st main column - with the graphs
      width = 6,
      fluidRow( # row with Little Falls flow graph
        box(
          title = "Potomac withdrawals - observed and forecasted",
          width = NULL,
          plotOutput("demands", height = plot.height, width = plot.width)
          # plotOutput("potomacFlows", height = "220px")
        )
      ) #,
      # fluidRow( # row with optional second graph
      #   # h3("Xxx"),
      #   column(
      #     width = 12,
      #     box(
      #       title = "Xxx",
      #       width = NULL,
      #       plotOutput("nbr_ten_day_plot", height = "220px")
      #     )
      #   )
      # ) # end of 2nd fluid row
    ), # end of 1st main column - with graphs
    column( # this is the 2nd main column - with values & triggers
      width = 6,
      box(title = "Yesterday's average Potomac withdrawals",
          width = NULL,
          height=60),
      valueBoxOutput("w_pot_fw_yesterday", width = NULL),
      valueBoxOutput("w_pot_wssc_yesterday", width = NULL),
      valueBoxOutput("w_pot_gf_yesterday", width = NULL),
      valueBoxOutput("w_pot_lf_yesterday", width = NULL),
      valueBoxOutput("w_pot_lw_yesterday", width = NULL)

      # br(),
      # box(title = "Jennings Randolph water supply release based on LFalls 9-day forecast from LFFS",
      #     width = NULL,
      #     height=60),
      # valueBoxOutput("lfalls_lffs_9day_fc", width = NULL),
      # valueBoxOutput("lffs_9day_deficit", width = NULL),
      # valueBoxOutput("luke_target2", width = NULL)
      # # valueBoxOutput("lfalls_obs", width = NULL)
    ) # end of 2nd main column
  ) # end of major column that contains whole body
) # end of major row that contains whole body

) # end of tab panel
