require(ggplot2)
require(tidyr)
require(dplyr)

dir = "../../data/temp"
data = Reduce(rbind,Map(read.csv,list.files(dir,pattern=".*csv$",full.name=T)))

data = data %>%
  filter(!(event == "block_start" & lag(event) == "off" &
           lag(event,2) == "block_start")) %>%
  group_by(sid) %>%
  mutate(trial = cumsum(event == "trial_start"),
         block = cumsum(event == "block_start"))

streams = data %>%
  group_by(sid,trial,block) %>%
  filter(block %in% 2:7,event %in% c('button1','button2')) %>%
  summarize(response = ifelse(last(event) == 'button1','stream1','stream2')) %>%

lengths = streams %>%
  group_by(sid) %>%
  filter(response != lag(response)) %>%
  mutate(length = trial - lag(trial))

ggplot(lengths,aes(x=2.8*length)) + geom_histogram() + xlim(0,2.8*30) +
  xlab('Percept Length (s)') + ylab('Count') +
  theme_set(theme_classic(base_size = 22))
ggsave(paste('../../plots/percept_lengths_',Sys.Date(),".pdf",sep=''),
       width=7,height=5)
