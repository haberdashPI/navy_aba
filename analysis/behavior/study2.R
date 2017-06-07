require(ggplot2)
require(dplyr)
require(tidyr)

## DESCRIPTION
##
## Initial work on a plot for study1. It's not very good yet (c.f. TODO's)

## TODO: remove the first part of each trial
## TODO: sort based on what response occured before deviant

data = rbind(read.csv('../../data/csv/david_study2_tone_0.0.1_6st_2017-06-01__08_37_38.csv'),
             read.csv('../../data/csv/david_study2_gap_0.0.1_6st_2017-06-01__07_13_43.csv'))

## response proportion following disruption, and elsewhere
lengths = c('gap' = 0.480, 'tone' = 1)

deviants = data %>%
  filter(code %in% c('gap','tone')) %>%
  mutate(length = lengths[code])

window_size = 4 # second
bin_size = 0.25 # seconds

minpos = function(xs) min(ifelse(xs > 0,xs,Inf))
closest_positive = function(xs,ys){
  X = outer(xs,ys,FUN="-")
  apply(X,1,minpos)
}

code_nums = c('stream_1' = 0, 'stream_2' = 1)
deviant_dists = data %>%
  select(trial,time,sid,deviant,code) %>%
  group_by(deviant) %>%
  mutate(
    deviant_distance = closest_positive(time,time[code %in% c('gap','tone')]),
    near_deviant = deviant_distance < window_size)

deviant_dists = deviant_dists %>%
  group_by(deviant) %>%
  mutate(duration = lead(time) - time)

wmean = function(x,w) sum(x*w) / sum(w)
wsd = function(x,w) (sum(w*(x-wmean(x,w))^2) / sum(w))

props = deviant_dists %>%
  group_by(deviant,near_deviant) %>%
  arrange(time) %>%
  mutate(window = floor((time - first(time))/window_size)) %>%
  group_by(deviant,near_deviant,window) %>%
  arrange(time) %>%
  mutate(bin = floor((time - first(time))/bin_size)) %>%
  group_by(deviant,near_deviant,bin) %>%
  filter(code %in% c('stream_1','stream_2')) %>%
  summarize(response = wmean(code_nums[as.character(code)],duration),
            sd = wsd(code_nums[as.character(code)],duration),
            N = length(unique(window)))

ggplot(props,aes(x=bin*bin_size,y=response,color=near_deviant)) +
  geom_ribbon(aes(ymin=response - sd / sqrt(N),
                  ymax=response + sd / sqrt(N),
                  group = near_deviant),
              color='white',fill='gray',alpha=0.6) +
  geom_line() +
  facet_wrap(~deviant) + xlab('Time (s)') + ylab('% streaming') +
  ylim(0,1) +
  theme_classic(base_size=16) + scale_color_brewer(palette='Set1')

ggsave(paste('../../plots/study2_mean_response_',Sys.Date(),'.pdf',sep=''),
       width=6,height=4)
