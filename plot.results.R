library(tidyr)
library(ggplot2)
library(dplyr)
source('trial_to_times.R')

file_pat = '[0-9]+_pilot_0.0.5_8st_2017.*.csv'
results = Reduce(rbind,Map(read.csv,list.files('data',file_pat,full.names=T)))

# TODO: come up with a better way to infer delayed responses

by_time = results %>%
  filter(code %in% c('stimulus','stream_1','stream_2')) %>%
  group_by(sid,trial) %>%
  do(trial_to_times(.,max_seconds=))

by_context = by_time %>%
	filter(response > 0) %>%
	group_by(sid,time) %>%
	summarise(response = mean(response-1))

legend = guide_legend(title='Context Stimulus')
ggplot(subset(by_context,sid == 0005),
	   aes(x=time,y=response)) +
	geom_line() + 
	theme_classic() + ylab('% streaming') + xlab('time (s)')

#ggsave(paste('data/speech_streaming_joel_',Sys.Date(),'.pdf',sep=''))
