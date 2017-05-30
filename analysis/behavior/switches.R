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

## block count for each sid
data %>% group_by(sid) %>% summarize(maxblock = max(block))

switches = subset(data,block %in% 9) %>%
  group_by(sid,trial) %>%
  filter(event %in% c('button1','button2')) %>%
  summarize(response = last(event))

means = switches %>%
  group_by(sid) %>%
  summarize(N = length(response), p_noswitch = mean(response == 'button1'))

means$aribtrary = 0

ggplot(means,aes(x=aribtrary,y=100*p_noswitch)) +
  geom_point(position=position_jitter(width=0.1),size=2.5,shape=21) +
  stat_summary(fun.data='mean_cl_boot',fun.args=list(conf.int=0.75),
               aes(group='mean',x=0.75),
               size=1.75,
               position=position_dodge(width=1)) +
  xlim(-0.5,1) + theme_classic(base_size = 22) +
  coord_cartesian(ylim=c(0,100)) +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) +
  xlab('') + ylab('% "no-switch" responses')

ggsave(paste('../../plots/noswitch_',Sys.Date(),".pdf",sep=''),
       width=3.5,height=4.5,useDingbats=F)
