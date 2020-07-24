#******************************************************************
# server.R defines reactive values & uses observeEvent to do simulation,
# then produces output
#******************************************************************
shinyServer(function(input, output, session) {
  # Multi-use
  source("code/server/dates_server.R", local = TRUE)
  source("code/server/process_lffs.R", local = TRUE)

  # Situational awareness tab
  source("code/server/situational_awareness/sit_aware_plots.R", local=TRUE)
  source("code/server/situational_awareness/sit_aware_valueboxes.R", local=TRUE)
  source("code/server/situational_awareness/sit_aware_MD.R", local=TRUE)
  source("code/server/situational_awareness/sit_aware_VA.R", local=TRUE)
  
  # One day ops tab
  source("code/server/one_day_ops/one_day_ops_server.R", local=TRUE)
  
  # Ten day ops tab
  source("code/server/ten_day_ops/ten_day_ops_server.R", local=TRUE)
  
  # Long term tab
  source("code/server/demands/demands_server.R", local=TRUE)
  
  # Simulation tab
  source("code/server/simulation/sim_run.R", local=TRUE)  
  source("code/server/simulation/sim_plots.R", local=TRUE)

  #Data Download tab
  source("code/server/download_data/download_data_server.R", local=TRUE)
  
  }) # end shinyServer

