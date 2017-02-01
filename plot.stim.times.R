library(tidyr)
library(ggplot2)
library(dplyr)
source('trial_to_times.R')

file_pat = '.+_pilot_.*_6st_2017.*.csv'
results = Reduce(rbind,Map(read.csv,list.files('data',file_pat,full.names=T)))

## timing of responses relative to the start of the last stimulus
trial_row = function(trial){
    start = subset(trial,code == 'trial_start')$time + 0.372 # == stim. length
    responses = subset(trial,code %in% c('stream_1','stream_2'))
    if(nrow(responses) > 0){
        data.frame(rt = last(responses$time) - start,
                   response = last(responses$code),
                   time = first(trial$time),
                   trial_length = last(trial$time) - first(trial$time))
    }else{
        data.frame(rt = NA,
                   response = NA,
                   time = first(trial$time),                   
                   trial_length = last(trial$time) - first(trial$time))
    }
}

find_int_times = function(trials){
    resps = subset(trials,response %in% c('stream_1','stream_2'))
    cur_stim = resps[1,]$response
    cur_stim_start = resps[1,]$time
    result = NULL
    for(row in 2:nrow(resps)){
        if(is.na(resps[row,]$response) ||
           is.na(cur_stim) || cur_stim != resps[row,]$response){
            x = data.frame(code=cur_stim,length=resps[row,]$time - cur_stim_start)
            result = rbind(result,x)
            cur_stim = resps[row,]$response
            cur_stim_start = resps[row,]$time
        }
    }
    x = data.frame(code=cur_stim,length=resps[nrow(resps),]$time - cur_stim_start)
    result = rbind(result,x)
}

int_trials = results %>%
    filter(trial >= 1,version == '0.0.6') %>%
    group_by(sid,trial) %>%
    do(trial_row(.))
    
int_times = int_trials %>%
    group_by(sid) %>%
    do(find_int_times(.))

find_cont_times = function(data){
    resps = subset(data,code %in% c('trial_start','stream_1','stream_2'))
    result = NULL
    cur_stim = resps[1,]$code
    cur_stim_start = resps[1,]$time
    for(row in 2:nrow(resps)){
        if(cur_stim != resps[row,]$code){
            if(cur_stim != 'trial_start'){
                x = data.frame(code=cur_stim,length=resps[row,]$time - cur_stim_start)
                result = rbind(result,x)
            }
            cur_stim = resps[row,]$code
            cur_stim_start = resps[row,]$time
        }
    }
    x = data.frame(code=cur_stim,length=resps[nrow(resps),]$time - cur_stim_start)
    result = rbind(result,x)

    result
}

cont_times = results %>%
    filter(trial >= 1,version == '0.0.7') %>%
    group_by(sid) %>%
    do(find_cont_times(.))
    #filter(trial_length < 3)

cont_times$type = 'continuous'
int_times$type = 'intermittant'
times = rbind(cont_times,int_times)

width = quantile(int_trials$trial_length,0.95)
ggplot(times,aes(x=length)) + geom_histogram(binwidth=width) + facet_grid(type~.)
ggplot(times,aes(x=length)) + geom_histogram(binwidth=width) + facet_grid(code~type)
ggsave("abin_percept_lengths.pdf")

ks.test(cont_times$length,int_times$length)
