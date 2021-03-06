# Finally, create boxes with values and triggers
#------------------------------------------------------------------
#------------------------------------------------------------------
#
#------------------------------------------------------------------
# Create value for yesterday's Potomac River flow at Point of Rocks
#------------------------------------------------------------------
  flows_yesterday.df <- flows.daily.mgd.df %>%
    filter(date_time == date_today0 - 1)

  output$por_flow <- renderValueBox({
  por_threshold <- 2000 # (cfs) CO-OP's trigger for daily monitoring/reporting
  potomac.ts.df <- ts$flows
  por_mgd <- flows_yesterday.df$por[1]
  
  # Error trapping: if POR daily flow yesterday is NA
  if(flows_yesterday.df$date_time <= flowday_last)
     por_flow <- paste("Flow at Point of Rocks yesterday = ",
                    round(por_mgd*mgd_to_cfs), " cfs",
                    " (", round(por_mgd), " MGD)", sep = "") else
                      por_flow <- "Yesterday's Point of Rocks daily flow value is not available"
  valueBox(
    value = tags$p(por_flow, style = "font-size: 60%;"),
    subtitle = NULL,
    #      color = if (por_flow >= por_threshold) "green" else "yellow"
    color = "blue"
  )
})

#------------------------------------------------------------------
# Create value for yesterday's Potomac River flow at Little Falls
#------------------------------------------------------------------
output$lfalls_obs <- renderValueBox({
  lfalls_mgd <- flows_yesterday.df$lfalls[1]
  lfalls_obs <- paste("Flow at Little Falls yesterday = ",
                      round(lfalls_mgd*mgd_to_cfs),
                      " cfs (", round(lfalls_mgd),
                      " MGD)", sep = "")
  # Error trapping: if LFalls daily flow yesterday is NA
  if(flows_yesterday.df$date_time <= flowday_last)
    lfalls_obs <- paste("Flow at Little Falls yesterday = ",
                      round(lfalls_mgd*mgd_to_cfs), " cfs",
                      " (", round(lfalls_mgd), " MGD)", sep = "") else
                        lfalls_obs <- "Yesterday's Little Falls daily flow value is not available"
  
  valueBox(
    value = tags$p(lfalls_obs, style = "font-size: 60%;"),
    subtitle = NULL,
    color = "blue"
  )
})
#------------------------------------------------------------------
# Create info on CO-OP operational status
#------------------------------------------------------------------
#
output$coop_ops <- renderUI({
  flows.last <- last(ts$flows)
  por_flow <- flows.last$por_nat[1]*mgd_to_cfs
  q_adj <- flows.last$lfalls_adj[1]
  withdr_pot <- flows.last$demand[1]

  #
  if(is.na(por_flow)) {
    text_stage <- "MISSING DATA"
    text_stage2 <- ""
    color_stage <- gray}
  else {
    if(por_flow > 2000) {
      text_stage <- "NORMAL"
      text_stage2 <- ""
      color_stage <- green}
    if(por_flow <= 2000) {
      text_stage <- "DAILY OPS" 
      text_stage2 <- "Daily monitoring & reporting"
      color_stage <- yellow}
    if(q_adj <= 100 + 2*withdr_pot) {
      text_stage <- "HOURLY OPS" 
      text_stage2 <- "Hourly monitoring & reporting"
      color_stage <- orange}
  }

  div(class="longbox",
      div(class="ibox", style = "background-color:silver",
          div(class="my_content",
              div(class="table",
                  div(class="table-cell2",
                      p(class = "p1",paste0("CO-OP operations status "))#,text_stage2))
                  )))),
      div(class="squarei", style = color_stage,
          div(class="my_content",
              div(class="table",
                  div(class="table-cell2",
                      p(class="p2",text_stage)
                  ))))
      
  ) # end div(class="longbox" 
}) # end renderUI
#------------------------------------------------------------------
# Create info on LFAA status
#------------------------------------------------------------------
#
output$lfaa_alert <- renderUI({
  flows.last <- last(ts$flows)
  q_adj <- flows.last$lfalls_adj[1]
  W <- flows.last$demand[1]
  #
  sen.last <- last(ts$sen)
  jrr.last <- last(ts$jrr)
  sen_stor <- sen.last$stor[1]
  jrr_ws_stor <- jrr.last$storage_ws[1]
  jrr_ws_cap_cp <- jrr_cap*jrr_ws_frac
  shared_ws_frac <- (sen_stor + jrr_ws_stor)/(sen_cap + jrr_ws_cap_cp)
  #
  if(q_adj > W/0.5) {
    text_stage <- "NORMAL"
    color_stage <- green
    text_stage2 <- ""}
  
  if(q_adj <= W/0.5 & q_adj > (W + 100)/0.8){
    text_stage <- "ALERT"
    color_stage <- yellow
    text_stage2 <- " (eligible)"}
  
  if(q_adj <= (W + 100)/0.8) {
    text_stage <- "RESTRICTION"
    color_stage <- orange
    text_stage2 <- " (eligible)"}
  
  if(shared_ws_frac <= 0.02){
    text_stage <- "EMERGENCY"
    color_stage <- red
    text_stage2 <- " (eligible)"}
  
  
  div(class="longbox",
      div(class="ibox", style = "background-color:silver",
          div(class="my_content",
              div(class="table",
                  div(class="table-cell2",
                      p(class = "p1",paste0("LFAA stage",text_stage2))#"Little Falls adj. flow, MGD "))#,text_stage2))
                  )))),
      div(class="squarei", style = color_stage,
          div(class="my_content",
              div(class="table",
                  div(class="table-cell2",
                      p(class="p2",text_stage)
                  ))))
      
  ) # end div(class="longbox"
}) # end renderUI
#
#------------------------------------------------------------------
# Create info on MWCOG Drought Plan stage
#------------------------------------------------------------------
# 
output$mwcog_stage <- renderUI({
  flows.last <- last(ts$flows)
  por_flow <- flows.last$por_nat[1]*mgd_to_cfs
  sen.last <- last(ts$sen)
  jrr.last <- last(ts$jrr)
  sen_stor <- sen.last$stor[1]
  jrr_ws_stor <- jrr.last$storage_ws[1]
  jrr_ws_cap_cp <- jrr_cap*jrr_ws_frac
  shared_ws_frac <- (sen_stor + jrr_ws_stor)/(sen_cap + jrr_ws_cap_cp)
  #
  # would 1500 cfs work as a surrogate for NOAA D1?
  noaa_d1_surrogate <- 1900
  if(por_flow > noaa_d1_surrogate) {
    text_stage <- "NORMAL" 
    text_stage2 <- "- Wise Water Use"
    color_stage <- green}
  if(por_flow <= noaa_d1_surrogate) { # surrogate
    # based on NOAA drought status - D1
    # then "notifications" upon 1st release, & when jrr+sen at 75%
    text_stage <- "WATCH" 
    text_stage2 <- "- Voluntary Water Conservation"
    color_stage <- yellow}
  if(shared_ws_frac <= 0.60){
    text_stage <- "WARNING"
    text_stage2 <- "- Voluntary Water Conservation"
    color_stage <- orange}
  # if(shared_ws_frac <= 0.05){
  if(shared_ws_frac <= 0.05){
    text_stage <- "EMERGENCY"
    text_stage2 <- "- Voluntary Water Conservation"
    color_stage <- red}
  
  div(class="longbox",
      div(class="ibox", style = "background-color:silver",
          div(class="my_content",
              div(class="table",
                  div(class="table-cell2",
                      p(class = "p1",paste0("MWCOG drought stage "))#,text_stage2))
                  )))),
      div(class="squarei", style = color_stage,
          div(class="my_content",
              div(class="table",
                  div(class="table-cell2",
                      p(class="p2",text_stage)
                  ))))
      
      
  ) # end div(class="longbox",
}) # end renderUI
#------------------------------------------------------------------
# Temporary output for QAing purposes
#------------------------------------------------------------------
output$QA_out <- renderValueBox({
  potomac.df <- ts$flows
  sen.df <- ts$sen
  jrr.df <- ts$jrr
  pat.df <- ts$pat
  occ.df <- ts$occ
  QA_out <- paste("Min flow at LFalls = ",
                  round(min(potomac.df$lfalls_obs, na.rm = TRUE)),
                  " mgd",
                  "________ Min sen, jrr, pat, occ stor = ",
                  round(min(sen.df$storage, na.rm = TRUE)), " mg, ",
                  round(min(jrr.df$storage_ws, na.rm = TRUE)), " mg,  ",
                  round(min(pat.df$storage, na.rm = TRUE)), " mg,  ",
                  round(min(occ.df$storage, na.rm = TRUE)),
                  " mg")
  valueBox(
    value = tags$p(QA_out, style = "font-size: 60%;"),
    subtitle = NULL,
    color = "blue"
  )
})
#------------------------------------------------------------------
#------------------------------------------------------------------
# Temporary output for QAing
#------------------------------------------------------------------

#------------------------------------------------------------------
#this outputs the last date to the login bar at the top right of the screen.
output$date_text  <- renderText({
  potomac.ts.df <- ts$flows
  test_date <- last(potomac.ts.df$date_time)
  paste("Today's date is ", as.character(date_today0),"  ")
})
#
