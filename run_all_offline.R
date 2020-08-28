#******************************************************************
# run_all_offline runs the model outside of Shiny, for QAing purposes
#******************************************************************
# First run global.R, which loads all data, paths, functions
# source("global.R", local = TRUE)

#******************************************************************
# Load packages ---------------------------------------------------------------  
# Use this one when not publishing to shinyapp.io, comment out when publishing:
source("code/global/load_packages.R", local = TRUE)
# Use this one when publishing, can comment out otherwise:
#source("code/global/import_packages.R", local = TRUE)

# Set paths -------------------------------------------------------------------

ts_path <- "input/ts/current/" # use for actual operations
# ts_path <- "input/ts/2019_drex/" # use for 2019 drought exercise

# Other paths -----------------------------------------------------------------
parameters_path <- "input/parameters/"
ts_output <- "output/" # path of output directory
map_path <- "data/Drought_Regions" #MD shapefiles
# Set "today's" date ----------------------------------------------------------
#    - Right now this needs to match last date in flows_daily_cfs.csv
date_today0 <- as.Date(today())

# For 2019 DREX
# date_today0 <- as.Date("2019-11-21")

#-----drought map functions are declared before they are used in import data
source("code/functions/display/md_drought_map_func.R", local = TRUE)
source("code/functions/display/va_drought_map_func.R", local = TRUE)
#------------------------------------------------------------------------------

#-----define parameters and import data ----------------------
# source("config/paths.R", local = TRUE)
source("input/parameters/parameters_ops.R", local = TRUE)
source("input/parameters/parameters_physical.R", local = TRUE)

#******************************************************************

# date_today0 is set in /input/parameters/parameters.R, 
#    but might want to change it, by using date_today
# date_today <- as.Date("1930-02-01")
date_today <- date_today0

  # Run the main simulation to the hard-coded input, date_today
  #    - ts here is the precursor of the set of reactive values
  ts0 <- list(sen = sen.ts.df0, 
              jrr = jrr.ts.df0, 
              pat = pat.ts.df0,
              occ = occ.ts.df0,
              flows = potomac.ts.df0)
  ts <- sim_main_func(date_today, ts0)
  #
  flows.ts.df <- ts$flows
  date_last <- flows.ts.df$date_time
  print(paste("After initial main run, the last date is ", date_last))
  # Now rerun, just as in the Shiny model
  ts <- sim_main_func(date_today, ts)
  flows.ts.df <- ts$flows
  date_last <- flows.ts.df$date_time
  print(paste("After second main run, the last date is ", date_last))
    #
  # Now add chunks of days twice
  chunkofdays <- 7
  ts <- sim_add_days_func(chunkofdays, ts)
  flows.ts.df <- ts$flows
  date_last <- flows.ts.df$date_time
  print(paste("After adding 1st chunkofdays, the last date is ", date_last))
  ts <- sim_add_days_func(chunkofdays, ts)
  flows.ts.df <- ts$flows
  date_last <- flows.ts.df$date_time
  print(paste("After adding 2nd chunkofdays, the last date is ", date_last))
  #
  # Now write some output
  write.csv(ts$flows, paste(ts_output, "offline_flows.csv"))
  write.csv(ts$sen, paste(ts_output, "offline_sen.csv"))
  write.csv(ts$jrr, paste(ts_output, "offline_jrr.csv"))
  write.csv(ts$occ, paste(ts_output, "offline_occ.csv"))
  write.csv(ts$pat, paste(ts_output, "offline_pat.csv"))
  #
  # The End