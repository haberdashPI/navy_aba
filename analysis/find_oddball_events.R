library(dplyr)
library(ggplot2)
library(tidyr)

# change these fields to analyze another file
## file = '../../data/jackie_2017_03_22/Jacki_03_22_17.evt'
## out_file_prefix = '../../data/jackie_2017_03_22/jackie_oddball_events'

file = '../../data/beatriz_2017_03_17/Beatriz_03_20_17.evt'
out_file_prefix = '../../data/beatriz_2017_03_17/beatriz_oddball_events'


data = rbind(read.delim(file,sep='\t')) %>%
    mutate(trigger = as.numeric(as.character(TriNo)),
           time = Tmu/1000000) %>%
    select(trigger,time)
data = data[order(data$time),]

stimulus_events = data %>%
    mutate(onset=lead(time),latency = lead(time) - time) %>%
    filter(trigger == 13,lead(trigger) == 256) %>%
    select(trigger,onset,latency)
mean(stimulus_events$latency < 0.03)
stimulus_events = filter(stimulus_events,latency < 0.03)

ggplot(subset(data,trigger %in% c(13,256) & time > 2110),
       aes(x=time,y=trigger)) + geom_point()

ggplot(stimulus_events,aes(x=onset,y=lead(onset) - onset)) + geom_point()

events = stimulus_events %>%
    mutate(Tmu = onset*10**6) %>%
    mutate(trigger = 400) %>%
    mutate(Code = 1) %>%
    mutate(TriNo = as.character(trigger)) %>%
    select(Tmu,Code,TriNo)

write.table(events,paste(out_file_prefix,Sys.Date(),'.evt',sep=''),
            row.names=F,sep='\t',quote=F)
