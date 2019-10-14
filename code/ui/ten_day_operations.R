tabPanel("Ten Day",
         fluidRow(
           align = "center",
           plotOutput("ten_day_plot", height = plot.height, width = plot.width),
           br()
         ) # End fluidRow
) # end of tab panel

# tabPanel("10-Day Ops",
#          fluidRow( # major row that contains whole body
#            column( # major column that contains whole body
#              width = 12,
#              #
#              # now add the content
#              column(  # this is the 1st main column - with the graphs
#                width = 6,
#                fluidRow( # row with Potomac flow graph
#                  box(
#                    title = "Put main graph here",
#                    width = NULL,
#                    plotOutput("ten_day", height = plot.height, width = plot.width)
#                    # plotOutput("potomacFlows", height = "220px")
#                  )
#                ),
#                fluidRow( # row with optional other graphs
#                  h3("Placeholder space for optional other graphs"),
#                  column(
#                    width = 12,
#                    box(
#                      title = "Maybe want another graph",
#                      width = NULL
#                      # plotOutput("jrrStorageReleases", height = "190px")
#                    )
#                  )
#                ) # end of 2nd fluid row
#              ), # end of 1st main column - with graphs
#              column( # this is the 2nd main column - with values & triggers
#                width = 6, 
#                box(
#                  title = "Put some values here - like 9-day deficit",
#                  width = NULL
#                  # plotOutput("jrrStorageReleases", height = "190px")
#                )
#                # valueBoxOutput("por_flow", width = NULL),
#                # valueBoxOutput("lfalls_obs", width = NULL)
#              ) # end of 2nd main column
#            ) # end of major column that contains whole body
#          ) # end of major row that contains whole body
#          
# ) # end of tab panel