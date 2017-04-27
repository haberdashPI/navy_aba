import sys
import os
import os.path as op
import numpy as np
import mne

execfile("local_settings.py")
execfile("src/find_blinks.py")

from mne.preprocessing import ICA

# first, show all the ICA components...
# then, select the blink pattern


names = ["Jared_04_03_17",
         "sandra_2017_03_31",
         "Jacki_03_22_17",
         "Beatriz_03_20_17",
         "1103_2017_04_24",
         "1102_2017_04_24",
         "1101_4-21-17",
         "1105_2017_04_26"]

data_dir = op.realpath(op.join("..","..","data"))

################################################################################

name = names[0]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

# TODO: figure out why IO1 and 2 on their own don't work below

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=1983)
ica.fit(raw,decim=2)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[7])
N = 7
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[1]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

# TODO: figure out why IO1 and 2 on their own don't work below

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=42)
ica.fit(raw,decim=2)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[2,11])
# ixs, scores = ica.find_bads_eog(blink_epochs)
# ica.plot_scores(scores,exclude=ixs)

N = 2
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))


################################################################################

name = names[2]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

# TODO: figure out why IO1 and 2 on their own don't work below

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=42)
ica.fit(raw,decim=2)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[4])
# ixs, scores = ica.find_bads_eog(blink_epochs)
# ica.plot_scores(scores,exclude=ixs)

N = 4
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[3]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

# TODO: figure out why IO1 and 2 on their own don't work below

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=42)
ica.fit(raw,decim=2)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[1,7])
# ixs, scores = ica.find_bads_eog(blink_epochs)
# ica.plot_scores(scores,exclude=ixs)

N = 7
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[4]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

# TODO: figure out why IO1 and 2 on their own don't work below

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=30,random_state=2001)
ica.fit(raw,decim=2)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[18])
N = 18
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[5]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

# TODO: figure out why IO1 and 2 on their own don't work below

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=42)
ica.fit(raw,decim=3)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[4])
N = 4
raw_noblinks = ica.apply(raw.copy(),exclude=[4])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[6]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

# TODO: figure out why IO1 and 2 on their own don't work below

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=1983)
ica.fit(raw,decim=3)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[9])
N = 9
raw_noblinks = ica.apply(raw.copy(),exclude=[9])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[7]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

# TODO: figure out why IO1 and 2 on their own don't work below

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=1983)
ica.fit(raw,decim=3)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[7])
N = 7
raw_noblinks = ica.apply(raw.copy(),exclude=[7])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))
