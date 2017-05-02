import sys
import os
import os.path as op
import numpy as np
import mne
import matplotlib.pyplot as plt

execfile("local_settings.py")
execfile("src/find_contrasts.py")

names = ["Jared_04_03_17",
         "sandra_2017_03_31",
         "Jacki_03_22_17",
         "Beatriz_03_20_17"]

stim_files = ["jared_2017_04_03/jared_stim_events_04_03_172017-04-06.evt",
              "sandra_2017_03_31/sandra_stim_events_2017_03_312017-04-06.evt",
              "jackie_2017_03_22/jackie_stream_events2017-03-29.evt",
              "beatriz_2017_03_17/beatriz_stream_events2017-03-29.evt"]

data_dir = op.realpath(op.join("..","..","data"))

stream12 = find_contrasts(names,stim_files,tmin=-0.2,tmax=2.8,
                          contrasts=dict(stream1=[110,111],stream2=[120,121]))
Cz = [stream12['mean']['stream1'].ch_names.index("Cz")]

mne.viz.plot_compare_evokeds(dict(stream1 = stream12['mean']['stream1'],
                                  stream2 = stream12['mean']['stream2']),
                             picks=Cz,
                             colors={'stream1': 'red', 'stream2': 'blue'},
                             ylim=dict(eeg=[2,-4]),show=False)
# TODO:
# setup nice format for figures
# plots for individual data
# standard errors
plt.savefig('stream12.pdf')

switch_a = find_contrasts(names,stim_files,tmin=-3.0,tmax=2.8,
                         baseline=(None,-2.8),
                         contrasts=dict(noswitch=[110,120],switch=[111,121]))

Cz = [switch_a['mean']['noswitch'].ch_names.index("Cz")]
mne.viz.plot_compare_evokeds(dict(noswitch = switch_a['mean']['noswitch'],
                                  switch = switch_a['mean']['switch']),
                             picks=Cz,
                             colors={'noswitch': 'red', 'switch': 'blue'},
                             ylim=dict(eeg=[2,-8]))

Cz = [switch_a['mean']['noswitch'].ch_names.index("Cz")]
mne.viz.plot_evoked(switch_a['mean']['switch - noswitch'],picks=Cz,
                    ylim=dict(eeg=[2,-8]))
plt

switch_b = find_contrasts(names,stim_files,tmin=-3.0,tmax=2.8,
                          baseline=(-0.2,0),
                          contrasts=dict(noswitch=[110,120],switch=[111,121]))

Cz = [switch_b['mean']['noswitch'].ch_names.index("Cz")]
mne.viz.plot_compare_evokeds(dict(noswitch = switch_b['mean']['noswitch'],
                                  switch = switch_b['mean']['switch']),
                             picks=Cz,
                             colors={'noswitch': 'red', 'switch': 'blue'},
                             ylim=dict(eeg=[3,-5]))


Cz = [switch_b['mean']['noswitch'].ch_names.index("Cz")]
mne.viz.plot_evoked(switch_b['mean']['switch - noswitch'],picks=Cz,
                    ylim=dict(eeg=[2,-8]))
