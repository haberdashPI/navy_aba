require(dplyr)
require(ggplot2)

oldf = "../../data/jared_2017_04_03/jared_stim_events_04_03_172017-04-06.evt"
newf = "../../data/temp/Jared_clean_events.evt"

old = read.table(oldf,header=T)
new = read.table(newf,header=T)

old$age = 'old'
new$age = 'new'
data = rbind(old,new)
