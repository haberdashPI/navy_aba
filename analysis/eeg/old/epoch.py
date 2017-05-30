import sys
import os
import os.path as op
import numpy as np
import mne
import matplotlib.pyplot as plt

execfile("local_settings.py")
execfile("src/find_contrasts.py")

# stim_files = ["jared_2017_04_03/jared_stim_events_04_03_172017-04-06.evt",
#               "sandra_2017_03_31/sandra_stim_events_2017_03_312017-04-06.evt",
#               "jackie_2017_03_22/jackie_stream_events2017-03-29.evt",
#               "beatriz_2017_03_17/beatriz_stream_events2017-03-29.evt"]

stim_files = map(lambda x: x.split("_")[0] + "_clean_events.evt",names)

################################################################################
# stream12

# TODO: introduce cahcing of the averages
stream12 = find_contrasts(names,stim_files,suffix="_cleaned",tmin=-0.2,tmax=2.8,
                          contrasts=dict(stream1=[110,111],stream2=[120,121]),
                          reject=dict(eeg=180e-6))
Cz = [stream12['mean']['stream1'].ch_names.index("Cz")]
re_reference(stream12,None)

mne.viz.plot_evoked_topo(stream12['mean'].values(),
                         color=['red','blue','lightgray'],
                         fig_facecolor='black',
                         axis_facecolor='black')

i = 0
mne.viz.plot_compare_evokeds(
  dict(stream1 = stream12['ind']['stream1'][i],
       stream2 = stream12['ind']['stream2'][i]),
  colors={'stream1': 'red', 'stream2': 'blue'},picks=Cz,
  show=False,ylim=dict(eeg=[3,-5]))


mne.viz.plot_compare_evokeds(
  dict(stream1 = [stream12['ind']['stream1'][i] for i in range(4)],
       stream2 = [stream12['ind']['stream2'][i] for i in range(4)]),
  picks=Cz,
  colors={'stream1': 'red', 'stream2': 'blue'},
  show=True)

mne.viz.plot_compare_evokeds(
  dict(stream1 = stream12['ind']['stream1'],
       stream2 = stream12['ind']['stream2']),
  colors={'stream1': 'red', 'stream2': 'blue'},picks=Cz,ci=0.0,
  show=False,ylim=dict(eeg=[3,-5]))
plt.savefig('../../plots/stream12_mean_'+str(datetime.date.today())+'.pdf')

mne.viz.plot_compare_evokeds(
  dict(stream1 = stream12['ind']['stream1'],
       stream2 = stream12['ind']['stream2']),
  colors={'stream1': 'red', 'stream2': 'blue'},picks=Cz,ci=0.682,
  show=False,ylim=dict(eeg=[5,-10]))
plt.savefig('../../plots/stream12_se_'+str(datetime.date.today())+'.pdf')

for i,sid in enumerate(names):
  mne.viz.plot_compare_evokeds(
    dict(stream1 = stream12['ind']['stream1'][i],
        stream2 = stream12['ind']['stream2'][i]),
    colors={'stream1': 'red', 'stream2': 'blue'},
    picks=Cz,ci=0.0,show=False,ylim=dict(eeg=[8,-15]))

  plt.savefig('../../plots/stream12_'+sid+'_'+str(datetime.date.today())+'.pdf')


mne.viz.plot_compare_evokeds(
  dict(stream1 = stream12['ind']['stream2 - stream1']),picks=Cz,ci=0.95,
  show=True,ylim=dict(eeg=[5,-8]))
plt.savefig('../../plots/stream12_se_'+str(datetime.date.today())+'.pdf')


stream12_noica = find_contrasts(names,stim_files,suffix="",tmin=-0.2,tmax=2.8,
                          contrasts=dict(stream1=[110,111],stream2=[120,121]),
                          reject=dict(eeg=180e-6))

mne.viz.plot_compare_evokeds(
  dict(stream1 = stream12_noica['ind']['stream1'],
       stream2 = stream12_noica['ind']['stream2']),
  colors={'stream1': 'red', 'stream2': 'blue'},picks=Cz,ci=0.0,
  show=False,ylim=dict(eeg=[4,-10]))

plt.savefig('../../plots/stream12_noica_'+str(datetime.date.today())+'.pdf')

################################################################################
# switches

switches = find_contrasts(names,stim_files,suffix="_noblink",
                          tmin=-3,tmax=2.8,baseline=(-0.2,0.0),
                          contrasts=dict(noswitch=[110,120],switch=[111,121]),
                          reject=dict(eeg=150e-6))
Cz = [switches['mean']['switch'].ch_names.index("Cz")]

mne.viz.plot_evoked_topo(switches['mean'].values(),
                         show=False,
                         color=['red','blue','lightgray'],
                         fig_facecolor='black',
                         axis_facecolor='black',
                         ylim = dict(eeg=[10,-10]))


switches = find_contrasts(names,stim_files,suffix="",
                          tmin=-3,tmax=2.8,baseline=(-0.2,0.0),
                          contrasts=dict(noswitch=[110,120],switch=[111,121]),
                          reject=dict(eeg=180e-6))
Cz = [switches['mean']['switch'].ch_names.index("Cz")]


mne.viz.plot_compare_evokeds(
  dict(switch = switches['ind']['switch'],
       noswitch = switches['ind']['noswitch']),ci=0.682,
  colors={'switch': 'red', 'noswitch': 'blue'},picks=Cz,
  show=False,ylim=dict(eeg=[10,-15]))
plt.savefig('../../plots/switch_se_'+str(datetime.date.today())+'mean.pdf')

mne.viz.plot_compare_evokeds(
  dict(switch = switches['ind']['switch'],
       noswitch = switches['ind']['noswitch']),
  colors={'switch': 'red', 'noswitch': 'blue'},picks=Cz,ci=0.0,
  show=False,ylim=dict(eeg=[5,-5]))
plt.savefig('../../plots/switch_'+str(datetime.date.today())+'mean.pdf')

for i,sid in enumerate(names):
  mne.viz.plot_compare_evokeds(
    dict(switch = switches['ind']['switch'][i],
         noswitch = switches['ind']['noswitch'][i]),
    colors={'switch': 'red', 'noswitch': 'blue'},
    picks=Cz,ci=0.0,show=False,ylim=dict(eeg=[8,-15]))

  plt.savefig('../../plots/switches_'+sid+'_'+str(datetime.date.today())+'.pdf')

switches_noica = find_contrasts(names,stim_files,suffix="",
                          tmin=-3,tmax=2.8,baseline=(-0.2,0.0),
                          contrasts=dict(noswitch=[110,120],switch=[111,121]),
                          reject=dict(eeg=180e-6))

mne.viz.plot_compare_evokeds(
  dict(switch = switches_noica['ind']['switch'],
       noswitch = switches_noica['ind']['noswitch']),
  colors={'switch': 'red', 'noswitch': 'blue'},picks=Cz,ci=0.0,
  show=False,ylim=dict(eeg=[5,-10]))
plt.savefig('../../plots/switch_noica_'+str(datetime.date.today())+'mean.pdf')

# NOTES: try 0.01 instead of 0.1 (0.1 can get rid of sutained activity)


# instructions: try to listen neutrally as best you can (you can influence
# which you hear).
# ask vanessa about payment needs
# take a peak at the protocol
