library(dplyr)
library(ggplot2)
library(tidyr)

# TODO: verify that funky timings are near break events

data = rbind(read.delim('data/karli_10-3-17.evt',sep='\t')) %>%
    mutate(trigger = as.numeric(as.character(TriNo)),
           time = Tmu/1000000) %>%
    select(trigger,time)
data = data[order(data$time),]

stimulus_events = data %>%
    mutate(onset=lead(time),latency = lead(time) - time) %>%
    filter(trigger == 9,lead(trigger) == 256) %>%
    select(trigger,onset,latency)
mean(stimulus_events$latency < 0.03)
stimulus_events = filter(stimulus_events,latency < 0.03)

responses = data %>%
    select(trigger,time) %>%
    filter(trigger %in% c(1:4,2048,4096))

## there was an error in the file: at some point cedrus responses were not
## recorded by weber just use the responses recorded directly from cecdrus to
## biosemi. unfortunately these are all offset rather than onset markers

resp1_down = responses %>%
    mutate(latency = (lead(time,2) - lead(time))) %>%
    mutate(onset = time - latency) %>%
    filter(trigger == 1,lead(trigger) == 2048,lead(trigger,2) == 3) %>%
    select(trigger,onset,latency)

resp1_up = responses %>%
    mutate(onset = time,latency = lead(time) - time) %>%
    filter(trigger == 2048,lead(trigger) == 3) %>%
    mutate(trigger = 3) %>%
    select(trigger,onset,latency)

resp2_down = responses %>%
    mutate(latency = (lead(time,2) - lead(time))) %>%
    mutate(onset = time - latency) %>%
    filter(trigger == 2,lead(trigger) == 4096,lead(trigger,2) == 4) %>%
    select(trigger,onset,latency)

resp2_up = responses %>%
    mutate(onset = time,latency = lead(time) - time) %>%
    filter(trigger == 4096,lead(trigger) == 4) %>%
    mutate(trigger = 4) %>%
    select(trigger,onset,latency)

data = rbind(stimulus_events,resp1_up,resp2_up)

## remove anything with an onset eralier than 250
## (this is the failed first block)
## data = data %>% filter(onset > 250)
old_data = data

## insert stimulus triggers in the expected location when they are missing
## (there are clear responses during these periods, indicating that the
## stimuli were indeed presented)

data = old_data
data = data[order(data$onset),]

trial_length = 2.8
data = data %>%
    filter(trigger %in% 9) %>%
    filter(abs(onset - lag(onset) - 3*trial_length) < 0.5) %>%
    mutate(onset = onset - trial_length) %>%
    rbind(data)

data = data[order(data$onset),]

data = data %>%
    filter(trigger %in% 9) %>%
    filter(abs(onset - lag(onset) - 2*trial_length) < 0.5) %>%
    mutate(onset = onset - trial_length,latency=NA) %>%
    rbind(data)
    
data = data[order(data$onset),]

# calcualte trial by trial responses
data_stim = data %>%
    mutate(trial = cumsum(ifelse(trigger == 9,1,0)) + 1) %>%
    group_by(trial) %>%
    mutate(resp = last(trigger[trigger %in% c(3,4)])) %>%
    filter(trigger %in% 9) %>%
    ungroup() %>%
    mutate(real_resp = ifelse(is.na(resp),0,resp)) %>%
    fill(resp) %>%
    mutate(switching = ifelse(trial != lag(trial),resp != lag(resp),NA)) %>%
    fill(switching) %>%
    filter(!is.na(resp)) %>%
    mutate(trial = trial - first(trial) + 1,trial_length = lead(onset) - onset)

data_stim[data_stim$trial == 1,'switching'] = FALSE
SOA = 0.700
data_stim = rbind(
    data_stim,
    data_stim %>% mutate(onset=onset+SOA,trigger=trigger+1),
    data_stim %>% mutate(onset=onset+2*SOA,trigger=trigger+2)
)
data_stim = data_stim[order(data_stim$onset),]

ggplot(data_stim,aes(y=as.numeric(lead(onset) - onset),x=onset)) +
    geom_vline(data=subset(data,trigger <= 4),
               aes(xintercept=onset,color=factor(trigger))) +
    ## geom_vline(data=subset(data,trigger==9),
    ##            aes(xintercept=onset),linetype=2) +
    geom_point() + ylim(0,10) 

ggplot(data_stim,aes(y=as.numeric(lead(onset) - onset),x=onset)) +
    geom_point() + ylim(0,10)

events = data_stim %>%
    mutate(Tmu = onset*10**6) %>%
    mutate(real_resp = ifelse(real_resp == 0,2,real_resp)) %>%
    mutate(trigger = (trigger-8)*100 + (real_resp-2)*10 + switching) %>%
    mutate(Code = 1) %>%
    mutate(TriNo = as.character(trigger)) %>%
    select(Tmu,Code,TriNo)

write.table(rbind(data.frame(Tmu=0,Code=41,TriNo="2017-03-07T2:25:00.000"),events),
            paste('karli_stim_events_',Sys.Date(),'.evt',sep=''),
            row.names=F,sep='\t',quote=F)

## TODO: code for individual beeps in aba, based on assumptions
## of stimulus presentation.
## different codes for different responeses
## differnet codes for different trials
# next version: one sound for all aba's
