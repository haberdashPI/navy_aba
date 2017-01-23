trial_to_times = function(trial,max_seconds=NA,
                          times=seq(0,max_seconds,length.out=100)){

    if(any(trial$phase %in% c('practice','example'))) return(data.frame())

	stim = subset(trial,code == 'stimulus')
	start_time = min(trial$time,na.rm=TRUE)
	responses = subset(trial,code %in% c('stream_1','stream_2'))
    if(nrow(responses)){
        data.frame(time = stim$time[1],response=trial[1],trial=stim$trial[1])
    }else data.frame()
}
