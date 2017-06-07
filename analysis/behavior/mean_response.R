require(ggplot2)
require(dplyr)
require(tidyr)

## DESCRIPTION:
##
## This generates a graph of the individual data for stream1 and stream2
## responses. Because plotting all of these at once is a little much, the graph
## actually bins responses and shows a mean for each window of time for each block
## and each listener.

source("../local_settings.R")
dir = file.path(data_dir,"events")
data = Reduce(rbind,Map(read.csv,list.files(dir,pattern=".*final.*csv$",full.name=T)))
exclude_sids = c(1111,1112,1113,1114) # unanalyzed in other graphs, so leave them out for now

n_bins = 15
block_length = 75*2.8 # number of trials x trial length (in seconds)
ind = data %>%
  filter(!(sid %in% exclude_sids)) %>%
  ## mutate(sid = as.numeric(factor(sid))) %>%
  mutate(response = response == 'button2') %>%
  group_by(sid,block) %>%
  mutate(bin = floor(n_bins * (time - first(time)) / block_length)) %>%
  group_by(sid,block,bin) %>%
  summarize(response = mean(response,na.rm=T))

ind = ind %>% data.frame() %>%
  select(response,bin,block,sid) %>%
  mutate(block = factor(block,levels=c(0:8,"mean")),
         sid = factor(sid,levels=c(unique(ind$sid),"mean"))) %>%
  filter(block != '0')

ggplot(ind,aes(x=bin*(75/n_bins),y=0,
                 color=cut(-response,9),
                 group = interaction(sid,block))) +
  facet_grid(sid~block) +
  geom_line(size=3) + scale_color_brewer(palette='RdBu') +
  theme_classic() +
  theme(axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  theme(panel.background = element_rect(fill='black'),
        panel.margin.x = unit(0.75, "lines"),
        panel.border = element_blank()) +
  scale_x_continuous(breaks=c(0,25,50,75),limits=c(0,75),expand=c(0,0)) +
  xlab("trial")

ggsave(paste('../../plots/response_ind_',Sys.Date(),".pdf",sep=''),
       width=8,height=4)


n_bins = 75
block_length = 75*2.8 # number of trials x trial length (in seconds)
example = data %>%
  filter(sid == 1106 & block == 6) %>%
  mutate(response = response == 'button2') %>%
  group_by(sid,block) %>%
  mutate(bin = floor(n_bins * (time - first(time)) / block_length)) %>%
  group_by(sid,block,bin) %>%
  summarize(response = mean(response,na.rm=T)) %>%
  data.frame() %>%
  select(response,bin,block,sid) %>%
  mutate(block = factor(block,levels=c(0:8,"mean")),
         sid = factor(sid,levels=c(unique(ind$sid),"mean"))) %>%
  filter(block != '0')

ggplot(example,aes(x=bin*(75/n_bins),y=0,
                   color=response < 0.5,
                   group = interaction(sid,block))) +
  geom_line(size=3) + scale_color_brewer(palette='Set1') +
  theme_classic() +
  theme(axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank()) +
  theme(panel.background = element_rect(fill='black'),
        panel.margin.x = unit(0.75, "lines"),
        panel.border = element_blank()) +
  scale_x_continuous(breaks=c(0,25,50,75),limits=c(0,75),expand=c(0,0)) +
  xlab("trial")

ggsave(paste('../../plots/response_ind_example_',Sys.Date(),".pdf",sep=''),
       width=6,height=0.75)
