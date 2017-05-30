from subprocess import call

import sys
import os
import os.path as op
import numpy as np
import mne

def notify(string):
  os.system("""osascript -e 'display notification """+'"'+string+'"'+""" with title "Ready"' """)

execfile("local_settings.py")
execfile("src/find_blinks.py")

from mne.preprocessing import ICA

# first, show all the ICA components...
# then, select the blink pattern

data_dir = op.realpath(op.join("..","..","data"))

################################################################################

name = names[0]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=150e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=1983)
ica.fit(epochs,decim=2)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[10,18,20,21,22,23])
N = 10
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[1]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=42)
ica.fit(raw,decim=2)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[2])

N = 2
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[2]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=30,method='extended-infomax',random_state=1983)
ica.fit(raw,decim=1)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[4])

N = 4
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[3]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=40,method='infomax',random_state=1989)
ica.fit(raw,decim=2)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[23])

N = 23
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[4]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='fastica',random_state=1983)
ica.fit(blink_epochs)

# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[19])
N = 19
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[5]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

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

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=1983)
ica.fit(raw,decim=3)
# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[11])
N = 11
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[7]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=30,method='extended-infomax',random_state=999666)
ica.fit(blink_epochs)

# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[1,2,8,28])
#N = 8
#raw_noblinks = ica.apply(raw.copy(),exclude=[N])

#raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))
raw.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################

name = names[8]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=18439)
ica.fit(raw,decim=3)

# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[6])
N=6
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################
# no good

name = names[9]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=30,method='extended-infomax',random_state=)
ica.fit(blink_epochs,decim=3)

# ica.plot_components()
# 13, 2, 12
# ica.plot_properties(blink_epochs,picks=[13,2,12])
N = 13
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))

################################################################################
# no good

name = names[10]
raw = mne.io.read_raw_fif(op.join(temp_dir,name+".fif"),preload=True)

epochs,eye_raw = epochs_for_blink_search(raw,reject=dict(eeg=300e-6),window_size=2,return_filtered=True)
blinks,channel_average = search_for_blinks(epochs,thresh=50e-6,window_size=2,return_average=True)

blink_events = np.stack([blinks ,
                         np.zeros(len(blinks)),
                         np.ones(len(blinks))]).astype('int_').T
blink_epochs = mne.Epochs(raw,blink_events,tmin=-0.4,tmax=0.4,baseline=None)

ica = ICA(n_components=25,method='extended-infomax',random_state=1983)
ica.fit(blink_epochs)

# ica.plot_components()
# ica.plot_properties(blink_epochs,picks=[11])
N = 11
raw_noblinks = ica.apply(raw.copy(),exclude=[N])

raw_noblinks.save(op.join(temp_dir,name+"_noblink.fif"))
