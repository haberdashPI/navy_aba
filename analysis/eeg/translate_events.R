library(dplyr)
library(ggplot2)
library(tidyr)

# change these fields to analyze another file
file = '../../data/beatriz_2017_03_17/Beatriz_03_20_17.evt'
out_file_prefix = '../../data/beatriz_2017_03_17/beatriz_stream_events'

data = rbind(read.delim(file,sep='\t')) %>%
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
    filter(trigger %in% c(1:4,4096,8192))

## there was an error in the file: at some point cedrus responses were not
## recorded by weber just use the responses recorded directly from cecdrus to
## biosemi. unfortunately these are all offset rather than onset markers

resp1_up = responses %>%
    filter(trigger == 4096) %>%
    mutate(trigger = 3,latency=NA,onset=time) %>%
    select(trigger,latency,onset)

resp2_up = responses %>%
    filter(trigger == 8192) %>%
    mutate(trigger = 4,latency=NA,onset=time) %>%
    select(trigger,latency,onset)

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
    geom_point() + ylim(0,10) + xlim(1000,1200)

ggplot(data_stim,aes(y=as.numeric(lead(onset) - onset),x=onset)) +
    geom_point() + ylim(0,10)

events = data_stim %>%
    mutate(Tmu = onset*10**6) %>%
    mutate(real_resp = ifelse(real_resp == 0,2,real_resp)) %>%
    mutate(trigger = (trigger-8)*100 + (real_resp-2)*10 + switching) %>%
    mutate(Code = 1) %>%
    mutate(TriNo = as.character(trigger)) %>%
    select(Tmu,Code,TriNo)

write.table(rbind(data.frame(Tmu=0,Code=41,TriNo=as.character(Sys.Date())),events),
            paste(out_file_prefix,Sys.Date(),'.evt',sep=''),
            row.names=F,sep='\t',quote=F)
