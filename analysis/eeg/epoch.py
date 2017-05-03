import sys
import os
import os.path as op
import numpy as np
import mne
import matplotlib.pyplot as plt

execfile("local_settings.py")
execfile("src/find_contrasts.py")

names = [
  "Jared_04_03_17",
  "sandra_2017_03_31",
  "Jacki_03_22_17",
  "Beatriz_03_20_17",
  "1101_4-21-17",
  "1102_2017_04_24",
  "1103_2017_04_24",
  "1105_2017_04_26"
]

# stim_files = ["jared_2017_04_03/jared_stim_events_04_03_172017-04-06.evt",
#               "sandra_2017_03_31/sandra_stim_events_2017_03_312017-04-06.evt",
#               "jackie_2017_03_22/jackie_stream_events2017-03-29.evt",
#               "beatriz_2017_03_17/beatriz_stream_events2017-03-29.evt"]

stim_files = [
  "Jared_clean_events.evt",
  "sandra_clean_events.evt",
  "Jacki_clean_events.evt",
  "Beatriz_clean_events.evt",
  "1101_clean_events.evt",
  "1102_clean_events.evt",
  "1103_clean_events.evt",
  "1105_clean_events.evt"
]

data_dir = op.realpath(op.join("..","..","data"))

# TODO: introduce cahcing of the averages
stream12 = find_contrasts(names,stim_files,tmin=-0.2,tmax=2.8,
                          contrasts=dict(stream1=[110,111],stream2=[120,121]))
Cz = [stream12['mean']['stream1'].ch_names.index("Cz")]

# mne.viz.plot_compare_evokeds(
#   dict(stream1 = [stream12['ind']['stream1'][i] for i in range(4)],
#        stream2 = [stream12['ind']['stream2'][i] for i in range(4)]),
#   colors={'stream1': 'red', 'stream2': 'blue'},
#   show=True)

mne.viz.plot_compare_evokeds(
  dict(stream1 = stream12['ind']['stream1'],
       stream2 = stream12['ind']['stream2']),
  colors={'stream1': 'red', 'stream2': 'blue'},picks=Cz,
  show=True,ylim=dict(eeg=[5,-10]))

mne.viz.plot_compare_evokeds(
  dict(stream1 = stream12['ind']['stream1'],
       stream2 = stream12['ind']['stream2']),
  colors={'stream1': 'red', 'stream2': 'blue'},picks=Cz,ci=0.0,
  show=True,ylim=dict(eeg=[3,-6]))


mne.viz.plot_compare_evokeds(
  dict(stream1 = stream12['ind']['stream1'],
       stream2 = stream12['ind']['stream2']),
  colors={'stream1': 'red', 'stream2': 'blue'},
  show=True)

plt.savefig('stream12.pdf')

# TODO: introduce cahcing of the averages
switches = find_contrasts(names,stim_files,
                          tmin=-3,tmax=2.8,baseline=(None,-2.8),
                          contrasts=dict(noswitch=[110,120],switch=[111,121]))
Cz = [switches['mean']['switch'].ch_names.index("Cz")]


mne.viz.plot_compare_evokeds(
  dict(switch = switches['ind']['switch'],
       noswitch = switches['ind']['noswitch']),
  colors={'switch': 'red', 'noswitch': 'blue'},picks=Cz,
  show=True,ylim=dict(eeg=[10,-15]))

# NOTES: try 0.01 instead of 0.1 (0.1 can get rid of sutained activity)


# instructions: try to listen neutrally as best you can (you can influence
# which you hear).
# ask vanessa about payment needs
# take a peak at the protocol
