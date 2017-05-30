require(ggplot2)
require(tidyr)
require(dplyr)

source("../eeg/local_settings.R")

dir = file.path(data_dir,"events")
strip.name = function(str){
  name = strsplit(str,"/")[[1]]
  name = name[length(name)]
  sid = strsplit(name,"_")[[1]]
  sid[1]
}
readf = function(file) cbind(read.table(file,header=T),sid=strip.name(file))
data = Reduce(rbind,Map(readf,list.files(dir,pattern=".*clean.*evt$",full.name=T)))

# exclude for now, since we haven't analyzed these ERPs
exclude = c('1110','1111')

ind = data %>%
  group_by(sid) %>%
  mutate(trial = 1:length(TriNo)) %>%
  filter(trial < 600,!(sid %in% exclude))

means = ind %>%
  group_by(sid) %>%
  summarize(streaming = mean(TriNo %in% c(120,121)),
            switching = mean(TriNo %in% c(111,121)))

means$aribtrary = 0

ggplot(means,aes(x=aribtrary,y=100*streaming)) +
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
  xlab('') + ylab('% "2 stream" responses')

ggsave(paste('../../plots/prop_streaming_',Sys.Date(),".pdf",sep=''),
       width=3.5,height=4.5,useDingbats=F)

ggplot(means,aes(x=aribtrary,y=100*switching)) +
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
  xlab('') + ylab('% switching responses')


ggsave(paste('../../plots/prop_switching_',Sys.Date(),".pdf",sep=''),
       width=3.5,height=4.5,useDingbats=F)
