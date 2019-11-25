# *****************************************************************************
# DESCRIPTION
# *****************************************************************************
# Load R packages, define classes and functions, and create time series df's
# Info found online:
#   "global.R is a script that is executed before
#    the application launch. For this reason, it can include the same
#    pieces of code to execute the reactive independent processes,
#    but it also has an additional capability: the objects 
#    generated in global.R can be used both in server.R and ui.R"
# *****************************************************************************
# INPUTS - NA
# *****************************************************************************

# *****************************************************************************
# OUTPUTS - NA
# *****************************************************************************

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Take care of preliminaries
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# Load packages ---------------------------------------------------------------  
# Use this one when not publishing to shinyapp.io, comment out when publishing:
# source("code/global/load_packages.R", local = TRUE)
# Use this one when publishing, can comment out otherwise:
source("code/global/import_packages.R", local = TRUE)

# Set paths -------------------------------------------------------------------

ts_path <- "input/ts/current/" # use for actual operations
# ts_path <- "input/ts/2019_drex/" # use for 2019 drought exercise

# Other paths -----------------------------------------------------------------
parameters_path <- "input/parameters/"
ts_output <- "output/" # path of output directory
map_path <- "data/Drought_Regions" #MD shapefiles

# Set "today's" date ----------------------------------------------------------
#    - Right now this needs to match last date in flows_daily_cfs.csv
# date_today0 <- as.Date(today())
date_today0 <- as.Date("2019-11-21")

#-----drought map functions are declared before they are used in import data
source("code/functions/display/md_drought_map_func.R", local = TRUE)
source("code/functions/display/va_drought_map_func.R", local = TRUE)
#------------------------------------------------------------------------------

#-----define parameters and import data ----------------------
# source("config/paths.R", local = TRUE)
source("input/parameters/parameters_ops.R", local = TRUE)
source("input/parameters/parameters_physical.R", local = TRUE)
source("code/global/import_data.R", local = TRUE)#
source("input/parameters/css_ui_values.R", local = TRUE)
source("code/global/complete_daily_flows.R", local = TRUE)
#----------------------------------------------------------------------------

# Read classes and functions --------------------------------------------------
source("code/classes/reservoir_class.R", local = TRUE)
source("code/functions/reservoir_ops/reservoir_ops_init_func.R", local = TRUE)
source("code/functions/reservoir_ops/reservoir_ops_today_func.R", local = TRUE)
source("code/functions/reservoir_ops/jrr_reservoir_ops_today_func.R", local = TRUE)
source("code/functions/reservoir_ops/jrr_reservoir_ops_today_func2.R", local = TRUE)
source("code/functions/forecast/forecasts_demands_func.R", local = TRUE)
source("code/functions/forecast/forecasts_flows_func.R", local = TRUE)
source("code/functions/state/state_indices_update_func.R", local = TRUE)
source("code/functions/simulation/estimate_need_func.R", local = TRUE)
source("code/functions/simulation/restriction_flow_benefits_func.R", local = TRUE)
source("code/functions/simulation/sim_main_func.R", local = TRUE)
source("code/functions/simulation/simulation_func.R", local = TRUE)
source("code/functions/simulation/sim_add_days_func.R", local = TRUE)
source("code/functions/simulation/rule_curve_func.R", local = TRUE)
source("code/functions/simulation/nbr_rule_curve_func.R", local = TRUE)
source("code/functions/display/display_graph_res_func.R", local = TRUE)

# Functions added by LukeV ----------------------------------------------------
source("code/functions/display/date_func.R", local = TRUE)
source("code/functions/display/warning_color_func.R", local = TRUE)
# this is a lazy Friday fix that should be changed later:
source("code/functions/display/warning_color_map_func.R", local = TRUE)


#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Create things that need to be accessed by everything
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# # Define today's date ---------------------------------------------------------
# #   - will usually be today
# #   - but want option to change to fake date for exercises
# 
# #---toggle
# date_today <- today()
# # date_today <- as.date("1999-07-01")
# #----

# Make reservoir objects and time series df's ---------------------------------
#   - the reservoir objects are jrr, sen, occ, pat
#   - the ts dfs are 
source("code/server/reservoirs_make.R", local = TRUE) 
# What this does is create the reservoir "objects", jrr, sen, occ, pat
#    and the reservor time series, res.ts.df
#    e.g., sen.ts.df - initialized with first day of ops time series

# Make the Potomac input data and flow time series dataframes -----------------
source("code/server/potomac_flows_init.R", local = TRUE)
# What this does is create:
# potomac.data.df - filled with all nat flow, trib flow data
# potomac.ts.df - initialized with first day of flows
#    - contains lfalls_obs, sen_outflow, jrr_outflow

# Make and initialize state drought status time series dataframes -------------
source("code/server/state_status_ts_init.R", local = TRUE)
# What this does is create:
# state.ts.df - filled with status indices:
#    - 0 = Normal
#    - 1 = Watch
#    - 0 = Warning
#    - 0 = Emergency

