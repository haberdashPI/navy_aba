library(dplyr)
library(ggplot2)
library(tidyr)

david = read.csv('data/David_events_2-22-17.csv') %>%
    mutate(TriNo = as.numeric(as.character(TriNo)))
david = david[order(davd$Time),]
stimulus_events = david %>%
    mutate(onset=lead(Time),latency = lead(Time) - Time) %>%
    filter(TriNo %in% 7:9,lead(TriNo) == 256,latency < 0.2) %>%
    select(TriNo,onset,latency)

responses = david %>%
    select(TriNo,Time) %>%
    filter(TriNo %in% c(1:6,2048,4096))

resp1_down = responses %>%
    mutate(latency = (lead(Time,2) - lead(Time))) %>%
    mutate(onset = Time - latency) %>%
    filter(TriNo == 1,lead(TriNo) == 2048,lead(TriNo,2) == 3) %>%
    select(TriNo,onset,latency)

resp1_up = responses %>%
    mutate(onset = Time,latency = lead(Time) - Time) %>%
    filter(TriNo == 2048,lead(TriNo) == 3) %>%
    mutate(TriNo = 3) %>%
    select(TriNo,onset,latency)

resp2_down = responses %>%
    mutate(latency = (lead(Time,2) - lead(Time))) %>%
    mutate(onset = Time - latency) %>%
    filter(TriNo == 2,lead(TriNo) == 4096,lead(TriNo,2) == 4) %>%
    select(TriNo,onset,latency)

resp2_up = responses %>%
    mutate(onset = Time,latency = lead(Time) - Time) %>%
    filter(TriNo == 4096,lead(TriNo) == 4) %>%
    mutate(TriNo = 4) %>%
    select(TriNo,onset,latency)

data = rbind(stimulus_events,resp1_down,resp1_up,resp2_down,resp2_up)
data = data[order(data$onset),]

data_stim = data %>%
    mutate(trial = cumsum(ifelse(TriNo == 7,1,0)) + 1) %>%
    group_by(trial) %>%
    mutate(resp = last(TriNo[TriNo %in% c(1,2)])) %>%
    filter(TriNo %in% 7:9) %>%
    ungroup() %>%
    mutate(real_resp = ifelse(is.na(resp),0,resp)) %>%
    fill(resp) %>%
    mutate(switching = ifelse(trial != lag(trial),resp != lag(resp),NA)) %>%
    fill(switching)
    
data_stim[data_stim$trial == 2,'switching'] = FALSE

# TODO: how do we handle missed trial responses?

events = data_stim %>%
    mutate(Tmu = onset*10**6) %>%
    mutate(TriNo = TriNo*100 + real_resp*10 + switching) %>%
    mutate(Code = 1) %>%
    mutate(Comnt = '') %>%
    select(Tmu,Code,TriNo,Comnt) %>%
    mutate(TriNo = as.character(TriNo))

write.table(rbind(data.frame(Tmu=0,Code=41,TriNo="2017-02-23T10:04:35.000",Comnt=""),events),
            paste('david_stim_events_',Sys.Date(),'.evt',sep=''),
            row.names=F,sep='\t',quote=F)


## TODO: code for individual beeps in aba, based on assumptions
## of stimulus presentation.
## different codes for different responeses
## differnet codes for different trials
# next version: one sound for all aba's
