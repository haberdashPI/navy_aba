require(ggplot2)
require(dplyr)
require(tidyr)

## DESCRIPTION
##
## Initial work on a plot for study1.

## data = rbind(read.csv('../../data/csv/david_study2_tone_0.0.1_6st_2017-06-01__08_37_38.csv'),
##              read.csv('../../data/csv/david_study2_gap_0.0.1_6st_2017-06-01__07_13_43.csv'))
## deviant_codes = c('tone','gap')

data = rbind(
  read.csv('../../data/csv/abin_itt_study2_ripple_0.1.0_2017-06-08__08_47_55.csv'),
  read.csv('../../data/csv/abin_study2_flash_0.1.0_2017-06-08__08_13_02.csv'),
  read.csv('../../data/csv/test_study2_ripple_0.1.0_2017-06-08__10_39_46.csv'),
  read.csv('../../data/csv/test_study2_flash_0.1.0_2017-06-08__10_04_28.csv'),
  read.csv('../../data/csv/mary_study2_ripple_0.1.0_2017-06-08__09_36_26.csv'))

deviant_codes = c('flash','ripple')

# find last response for each row
marked = data %>%
  select(trial,time,sid,deviant,code) %>%
  group_by(sid,deviant) %>%
  mutate(duration = lead(time) - time) %>%
  group_by(sid,deviant,trial,
           response_index = cumsum(code %in% c('stream_1','stream_2'))) %>%
  mutate(last_response = ifelse(first(code) %in% c('stream_1','stream_2'),
                                as.character(first(code)),'none'))

# find distance to deviant, and the response during the deviant
marked_indexed = marked %>%
  group_by(sid,deviant) %>%
  mutate(deviant_index = cumsum(code %in% deviant_codes)) %>%
  group_by(sid,deviant,deviant_index) %>%
  mutate(deviant_distance = time - first(time),
         response_on_deviant = first(last_response))

## use only response after the first deviant
## (maybe we should wait for bi-stability?)
after_deviants = marked_indexed %>%
  group_by(sid,deviant,trial) %>%
  arrange(time) %>%
  filter(deviant_index > 0) %>%
  data.frame()

## collect a window following each deviant

## period in which a deviant cannot occur
## 120ms = tone SOA
## 120ms x 4 = 480ms = ABA SOA
## 120ms x 4 x 2 = 1/2 of deviant spacing
window_size = (120*4*6)/1000
bin_size = 0.1 # seconds

wmean = function(x,w) sum(x*w) / sum(w)
wsd = function(x,w) (sum(w*(x-wmean(x,w))^2) / sum(w))

deviant_time_course = after_deviants %>%
  mutate(near_deviant = deviant_distance < window_size) %>%
  group_by(sid,deviant,trial,deviant_index,response_on_deviant) %>%
  mutate(bin = floor((time - first(time))/bin_size)) %>%
  group_by(sid,deviant,trial,deviant_index,response_on_deviant,bin) %>%
  filter(code %in% c('stream_1','stream_2')) %>%
  summarize(response = wmean(code == 'stream_2',duration))

non_deviant_time_course = after_deviants %>%
  filter(deviant_distance > 2*window_size) %>%
  group_by(sid,deviant,trial,deviant_index) %>%
  mutate(window = floor((time-first(time))/window_size)) %>%
  group_by(sid,deviant,trial,deviant_index,window) %>%
  mutate(first_response = first(last_response)) %>%
  group_by(sid,deviant,trial,deviant_index,window,first_response) %>%
  mutate(bin = floor((time - first(time))/bin_size)) %>%
  group_by(sid,deviant,trial,deviant_index,first_response,window,bin) %>%
  filter(code %in% c('stream_1','stream_2')) %>%
  summarize(response = wmean(code == 'stream_2',duration))

time_course = rbind(
  deviant_time_course %>% data.frame() %>%
    mutate(near_deviant=T,start_response = response_on_deviant) %>%
    select(sid,deviant,trial,bin,response,near_deviant,start_response) %>%
    data.frame(),
  non_deviant_time_course %>% data.frame() %>%
    mutate(near_deviant=F,start_response = first_response) %>%
    select(sid,deviant,trial,bin,response,near_deviant,start_response) %>%
    data.frame())

for(csid in unique(time_course$sid)){
  ggplot(time_course %>% filter(sid == csid,start_response != 'none'),
         aes(x=bin*bin_size,y=response,color=near_deviant)) +
    stat_summary(fun.data='mean_cl_boot',geom='smooth',
                 fun.args=list(conf.int=0.75)) +
    facet_grid(start_response~deviant) + xlab('Time (s)') + ylab('% streaming') +
    ylim(0,1) + xlim(0,window_size) +
    theme_classic(base_size=16) + scale_color_brewer(palette='Set1')

  ggsave(paste('../../plots/study2_',csid,'_response_',Sys.Date(),'.pdf',sep=''),
         width=6,height=4)

}
