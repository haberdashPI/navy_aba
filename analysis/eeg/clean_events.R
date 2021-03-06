require(tidyr)
require(dplyr)
require(ggplot2)
source('../local_settings.R')

event_data_dir = file.path(data_dir,"events/")
data = Reduce(rbind,Map(read.csv,list.files(event_data_dir,pattern='.*_events.csv',full.name=T)))

stim_starts = data %>%
  filter(event == 'stimulus' & lead(event) == 'trial_start' &
         lead(time) - time < 0.2)

latencies = data %>%
  mutate(latency = lead(time) - time) %>%
  filter(event =='stimulus' & lead(event) == 'trial_start')

buttons = filter(data,event %in% c("button1","button2"))
blocks = data %>%
  group_by(sid) %>%
  filter(event == 'block_start') %>%
  filter(time - lag(time) > 0.5*2.8*75 | is.na(lag(time)))

trials = rbind(stim_starts,buttons,blocks) %>%
  group_by(sid) %>%
  arrange(time) %>%
  mutate(trial = cumsum(event == 'stimulus'),
         block = cumsum(event == 'block_start'))

stream12 = trials %>%
  group_by(sid,block,trial) %>%
  filter(event %in% c('stimulus','button1','button2'),block < 9) %>%
  mutate(event = as.character(event)) %>%
  summarize(
    time = ifelse(all(event != 'stimulus'),head(time,1),
                  head(time[event == 'stimulus'],1))[1],
    response = tail(event[event != 'stimulus'],1)[1]) %>%
  mutate(isswitch = is.na(lag(response)) | response != lag(response),
         response = factor(response))

switches = trials %>%
  group_by(sid,block,trial) %>%
  filter(event %in% c('stimulus','button1','button2'),block > 9) %>%
  mutate(event = as.character(event)) %>%
  summarize(
    time = ifelse(all(event != 'stimulus'),head(time,1),
                  head(time[event == 'stimulus'],1))[1],
    response = tail(event[event != 'stimulus'],1)[1]) %>%
  mutate(response = factor(response))

#ggplot(stream12,aes(y=sid,x=trial,color=response)) + geom_point()
#ggplot(switches,aes(y=sid,x=trial,color=response)) + geom_point()

besa_events = stream12 %>%
  mutate(Tmu = as.integer(round(time*10**6)),
         TriNo = 100 + 10*ifelse(is.na(response),0,1+(response=='button2')) +
           1*ifelse(is.na(isswitch),0,isswitch),
         Code = 1) %>% data.frame()

eeglab_events = stream12 %>%
  mutate(Latency = time,
         Type = 100 + 10*ifelse(is.na(response),0,1+(response=='button2')) +
           1*ifelse(is.na(isswitch),0,isswitch)) %>% data.frame()

for(mysid in unique(besa_events$sid)){
  print(mysid)
  sdata = subset(besa_events,sid == mysid) %>% data.frame() %>%
    select(Tmu,Code,TriNo)
  write.table(sdata,
              paste(event_data_dir,"/",mysid,'_clean_events.evt',sep=''),
              row.names=F,sep='\t',quote=F)

  sdata = subset(eeglab_events,sid == mysid) %>% data.frame() %>%
    select(Latency,Type)
  write.table(sdata,
               paste(event_data_dir,"/",mysid,'_clean_events.txt',sep=''),
              row.names=F,sep='\t',quote=F)

  sdata = subset(stream12,sid == mysid) %>% data.frame()
  write.csv(sdata,paste(event_data_dir,"/",mysid,"_events_final.csv",sep=''))
}
