import sys
import os
import os.path as op
import numpy as np
import mne
import pandas as pd
import progressbar
from mne.preprocessing import ICA
from mne.preprocessing.peak_finder import peak_finder
from numba import jit
from mne.preprocessing import compute_proj_eog

################################################################################
# load raw data
dir_path = op.realpath("..")
file = op.join(dir_path,"data","david_2017_03_13",
               "David_take2_3-10-17.bdf")
raw = mne.io.read_raw_edf(file,preload=True,
                          misc=['Erg1'],
                          eog=['IO1','IO2','LO1','L02'],
                          montage=op.join(dir_path,'data','acnlbiosemi64.sfp'))

raw.info['bads'] += ['Erg1','AF7','F3']
# TODO: mark STI as stim channel

################################################################################
# filtering
raw = raw.filter(0.1,30,l_trans_bandwidth='auto',
                h_trans_bandwidth='auto',
                filter_length='auto',phase='zero')

################################################################################
# re-reference to mastoids
mne.set_eeg_reference(raw,copy=False,ref_channels=['M1','M2'])

################################################################################
# eyeblink artifact correction

# create regulalry windowed epochs...
window_step = 5
window_half_size = 2.7

# look only in frequencies close to the eyeblink rate
eye_raw = raw.copy().filter(l_freq=2,h_freq=8,
                            l_trans_bandwidth='auto',filter_length='auto',
                            h_trans_bandwidth='auto',
                            phase='zero')
events = raw.time_as_index(np.arange(raw.times[0],raw.times[-1],1))
evt_mat = np.stack([events,
                    np.zeros(len(events)),
                    np.ones(len(events))]).astype('int_')
epochs = mne.Epochs(eye_raw,evt_mat.T,tmin=-window_half_size,tmax=window_half_size,
                    reject=dict(eeg=150e-6),baseline=None)
epochs.drop_bad()
dropped = sum(map(lambda x: len(x) > 0,epochs.drop_log))
print "%2.1f%% of epochs dropped" % (100*dropped/(dropped+float(len(epochs))))

########################################
# find peaks and assume they're blinks
blinks = []
peak_indices = -np.ones(100,dtype='int_')
count = 0
bar = progressbar.ProgressBar(max_value=len(epochs.selection)-1)
picks = mne.pick_types(raw.info,eeg=True,eog=True)
window_start = np.floor(raw.info['sfreq']*-window_half_size).astype('int_')

oldout = sys.stdout
null = open(os.devnull,'w')
for evoked in epochs.iter_evoked():
  bar.update(count)
  index_offset = evt_mat[0,epochs.selection[count]] + window_start
  channel_average = np.mean(evoked.data[picks,:],axis=0)
  sys.stdout = null
  indices,_ = peak_finder(channel_average,25e-6) + index_offset #findpeaks(channel_average,peak_indices) + index_offset
  sys.stdout = oldout
  blinks = np.concatenate([blinks,indices.astype('int_')])
  count += 1
  # if count > 2:
  #   break
null.close()

blinks = np.unique(blinks)
blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T

blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

# extract ICA components and remove the component that looks most like these blinks
ica = ICA(n_components=25,method='fastica',random_state=27)
ica.fit(raw, picks=mne.pick_types(raw.info,eeg=True), decim=5)

#IC 20 looks good...
raw_noblinks = ica.apply(raw,exclude=[20])

################################################################################
# TODO: generate simple averaged epochs to start
event_file = op.join(dir_path,"data","david_2017_03_13",
                     "david_stim_events_2017-03-13.evt")
events = pd.read_table(event_file)
events['samples'] = np.floor(events.Tmu * 1e-6 * 512)
events['dummy'] = 0
events['stream12'] = (2*events['trigger'].isin([120,121]) +
                      1*events['trigger'].isin([110,111]))

stream12 = events[['samples','dummy','stream12']].as_matrix().astype('int_')

picks = mne.pick_types(raw.info,eeg=True,eog=True)
epochs = mne.Epochs(raw_noblinks,stream12,event_id = {'stream1': 1, 'stream2': 2},
                    reject=dict(eeg=150e-6),picks=picks,
                    tmin=-0.2,tmax=2.8)

evoked_stream1 = epochs['stream1'].average()
evoked_stream2 = epochs['stream2'].average()
print "%2.1f%% of stream1 kept" % (100*(float(evoked_stream1.nave) / sum(events['stream12']==1)))
print "%2.1f%% of stream2 kept" % (100*(float(evoked_stream2.nave) / sum(events['stream12']==2)))

evoked12 = mne.combine_evoked([evoked_stream1,-evoked_stream2],weights='equal')
