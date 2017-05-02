require(tidyr)
require(dplyr)
require(ggplot2)

names = c("Jared_04_03_17",
          "sandra_2017_03_31",
          "Jacki_03_22_17",
          "Beatriz_03_20_17",
          "1103_2017_04_24",
          "1102_2017_04_24",
          "1101_4-21-17")

temp_data_dir = '../../data/temp'
data = Reduce(rbind,Map(read.csv,list.files(temp_data_dir,pattern='.*_events.csv',full.name=T)))

stim_starts = data %>%
  filter(event == 'stimulus' & lead(event) == 'trial_start' &
         lead(time) - time < 0.2)

buttons = filter(data,event %in% c("button1","button2"))
blocks = data %>%
  filter(!(event == "block_start" & lag(event) == "off" &
           lag(event,2) == "block_start")) %>%
  filter(event == 'block_start')

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
    time = ifelse(all(event != 'stimulus'),first(time),
                  first(time[event == 'stimulus'])),
    response = last(event[event != 'stimulus'])) %>%
  mutate(isswitch = is.na(lag(response)) | response != lag(response),
         response = factor(response))

switches = trials %>%
  group_by(sid,block,trial) %>%
  filter(event %in% c('stimulus','button1','button2'),block > 9) %>%
  mutate(event = as.character(event)) %>%
  summarize(
    time = ifelse(all(event != 'stimulus'),first(time),
                  first(time[event == 'stimulus'])),
    response = last(event[event != 'stimulus'])) %>%
  mutate(response = factor(response))

ggplot(stream12,aes(y=sid,x=trial,color=response)) + geom_point()
ggplot(switches,aes(y=sid,x=trial,color=response)) + geom_point()

events = stream12 %>%
  mutate(Tmu = as.integer(round(time*10**6)),
         TriNo = 100 + 10*ifelse(is.na(response),0,1+(response=='button2')) +
           1*ifelse(is.na(isswitch),0,isswitch),
         Code = 1) %>% data.frame()

for(mysid in unique(events$sid)){
  sdata = subset(events,sid == mysid) %>% data.frame() %>% select(Tmu,Code,TriNo)
  write.table(sdata,
              paste('../../data/temp/',mysid,'_clean_events.evt',sep=''),
              row.names=F,sep='\t',quote=F)
}
