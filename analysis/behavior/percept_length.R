require(ggplot2)
require(tidyr)
require(dplyr)

source("../eeg/local_settings.R")

dir = file.path(data_dir,"events")
data = Reduce(rbind,Map(read.csv,list.files(dir,pattern=".*csv$",full.name=T)))

data = data %>%
  filter(!(event == "block_start" & lag(event) == "off" &
           lag(event,2) == "block_start")) %>%
  group_by(sid) %>%
  mutate(trial = cumsum(event == "trial_start"),
         block = cumsum(event == "block_start"))

streams = data %>%
  group_by(sid,trial,block) %>%
  filter(block %in% 0:9,event %in% c('button1','button2')) %>%
  summarize(response = ifelse(last(event) == 'button1','stream1','stream2'))

lengths = streams %>%
  group_by(sid) %>%
  filter((response != lag(response) & !is.na(lag(response))) |
         row_number() == 1) %>%
  mutate(length = lead(trial) - trial)

## ggplot(lengths,aes(x=2.8*length)) + geom_histogram() + xlim(0,2.8*30) +
##   xlab('Percept Length (s)') + ylab('Count') +
##   theme_set(theme_classic(base_size = 22))
## ggsave(paste('../../plots/percept_lengths_',Sys.Date(),".pdf",sep=''),
##        width=7,height=5)

first_phases = lengths %>%
  group_by(sid) %>%
  top_n(20) %>%
  arrange(trial) %>%
  mutate(phase = 1:length(sid))

ggplot(first_phases,aes(x=phase,y=log(length))) +
  stat_summary(geom='bar') +
  stat_summary(geom='errorbar',width=0.3) + scale_x_continuous(breaks=1:7) +
  ## geom_point() +
  xlim(0.5,7.5) +
  theme_classic(base_size = 22) +
  xlab('Phase #') + ylab('Log of Duaration')

ggsave(paste('../../plots/first7_',Sys.Date(),".pdf",sep=''),
       width=5,height=5)

normalized = lengths %>%
  group_by(sid) %>%
  mutate(phase = 1:length(sid)) %>%
  filter(phase > 1) %>%
  mutate(normed = log(length)+1 / mean(log(length)+1,na.rm=T),
         norm = mean(log(length),na.rm=T))

ggplot(normalized,aes(x=normed,fill=response)) +
  geom_histogram(aes(y=..density..), bins = 20,alpha=0.65,
                 position="identity",color='black') +
  xlab('Normalized duration') + ylab('# of occurances') +
  scale_fill_brewer(palette='Set1') +
  theme_classic(base_size=22)


ggplot(normalized,aes(x=normed)) +
  geom_histogram(bins = 20,position="identity",fill='gray',color='black') +
  xlab('Normalized duration') + ylab('# of occurances') +
  theme_classic(base_size=22)

ggsave(paste('../../plots/norm_lengths_',Sys.Date(),".pdf",sep=''),
       width=5,height=5)

next_lengths = lengths %>%
  group_by(sid) %>%
  mutate(phase = 1:length(sid)) %>%
port  filter(phase > 1) %>%
  mutate(length_n = log(length),length_n1 = log(lead(length)))

ggplot(next_lengths,aes(x=length_n,y=length_n1)) + geom_point() +
  xlab('# trials (phase N)') + ylab('# trials (phase N+1)')

ggsave(paste('../../plots/length_cor_',Sys.Date(),".pdf",sep=''),
       width=5,height=5)
