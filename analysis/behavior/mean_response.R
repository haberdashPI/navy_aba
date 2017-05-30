
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

ind = data %>%
  mutate(response = ifelse(TriNo %in% c(110,111),'stream1',
                           ifelse(TriNo %in% c(120,121),'stream2',NA))) %>%
  group_by(sid) %>%
  mutate(trial = 1:length(response)) %>%
  filter(trial < 600)

chunk_size = 3
asnum = ind %>%
  mutate(chunk = as.integer(trial/chunk_size),
         response = response == 'stream2')

ggplot(asnum,aes(x=trial,y=100*response)) +
  stat_summary(geom='line',color='gray',size=0.5) + geom_smooth() +
  xlab('Trial') + theme_classic(base_size = 22) + ylim(0,100) +
  geom_hline(yintercept=50,linetype=2) + ylab('% 2-stream')

ggsave(paste('../../plots/response_mean_',Sys.Date(),".pdf",sep=''),
       width=5.5,height=3.5)

ggplot(ind,aes(x=trial,y=sid,color=response)) + geom_point() +
  theme_classic(base_size = 22) +
  theme(axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  scale_color_brewer(palette='Set1')

ggsave(paste('../../plots/response_ind_',Sys.Date(),".pdf",sep=''),
       width=5.5,height=2.5)
