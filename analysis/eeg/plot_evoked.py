from copy import deepcopy
import datetime
import os
import os.path as op
import mne
import pandas as pd
import numpy as np
import re
import matplotlib.pyplot as plt

execfile("local_settings.py")

data = pd.read_csv(op.join(data_dir,"NAVY_aba_n11_5-10-17_av_cc-export.mul"),
                   skiprows=1,sep='\s+')
data.rename(columns=lambda x: re.sub(r"(\w+)_mast", r"\1",x),inplace=True)

info = mne.create_info(
  ch_names = list(data.columns),
  ch_types = np.hstack([np.repeat('eeg',72),np.repeat('misc',1)]),
  sfreq = 512
)

conditions = np.array(['stream1','stream2','noswitch','switch',
                       'stream2-stream1','switch-noswitch','none'])
times = np.cumsum([3,3,5.8,5.8,3,5.8]) - 1/512.0
data['time'] = np.array(data.index) / 512.0
index = np.sum(data.time[:,np.newaxis] > times[np.newaxis,:],axis=1)
data['condition'] = conditions[index]

evokeds = {}
stream_cond = ['stream1','stream2','stream2-stream1']
stream_len = data[data.condition.isin(stream_cond)].groupby('condition').time.count().min()
for cond in stream_cond:
  montage = mne.channels.read_montage(op.join(data_dir,"..","acnlbiosemi64.sfp"))
  evoked = mne.EvokedArray(data.ix[data.condition == cond,0:73][0:stream_len].as_matrix().T*10**-6,info)
  evoked.times -= 0.2
  evoked.set_montage(montage)
  evoked.comment = cond
  evokeds[cond] = evoked

# mne.viz.plot_evoked_topo([evokeds[k] for k in stream_cond])
FCz = [evokeds['stream1'].ch_names.index("FCz")]
fig = mne.viz.plot_compare_evokeds(
  {'stream1': evokeds['stream1'],
   'stream2': evokeds['stream2'],
   'stream2-stream1': evokeds['stream2-stream1']},
  styles = {
    'stream1': {"linewidth": 3},
    'stream2': {"linewidth": 3},
    'stream2-stream1': {"linewidth": 3}
  },
  colors={'stream1': 'red', 'stream2': 'blue', 'stream2-stream1': 'black'},picks=FCz,
  show=False,invert_y=True)
plt.rcParams.update({'font.size': 22})
fig.set_size_inches(7,3)
# plt.show()
times = [0.075, 0.200, 0.570, 1.120]
for t in times:
  plt.axvline(x=t,color='black',linestyle='--')

fig.savefig('../../plots/stream12_mean_'+str(datetime.date.today())+'.pdf')

# mne.viz.plot_evoked(evokeds['stream2-stream1'],picks=FCz,ylim=dict(eeg=[2,-2]))

average = mne.set_eeg_reference(evokeds['stream2-stream1'],ref_channels=None)[0]
average.apply_proj()
fig = evokeds['stream2-stream1'].plot_topomap(times=times,
                                              show=False)
fig.set_size_inches(9,4)
# plt.show()
fig.savefig('../../plots/stream12_mean_topo_'+str(datetime.date.today())+'.pdf')

evokeds = {}
switch_cond = ['switch','noswitch','switch-noswitch']
stream_len = data[data.condition.isin(switch_cond)].groupby('condition').time.count().min()
for cond in switch_cond:
  montage = mne.channels.read_montage(op.join(data_dir,"..","acnlbiosemi64.sfp"))
  sub = data.ix[data.condition == cond,0:73][0:stream_len]
  sub = sub[np.floor(512*2.5).astype('int_'):(512*4+1)]
  evoked = mne.EvokedArray(sub.as_matrix().T*10**-6,info)
  evoked.times -= 0.5
  evoked.apply_baseline((-0.2,0))
  evoked.set_montage(montage)
  evoked.comment = cond
  evokeds[cond] = evoked

# mne.viz.plot_evoked_topo([evokeds[k] for k in switch_cond])

FCz = [evokeds['noswitch'].ch_names.index("FCz")]
fig = mne.viz.plot_compare_evokeds(
  {'noswitch': evokeds['noswitch'],
   'switch': evokeds['switch'],
   'switch-noswitch': evokeds['switch-noswitch']},
  styles = {
    'noswitch': {"linewidth": 3},
    'switch': {"linewidth": 3},
    'switch-noswitch': {"linewidth": 3}
  },
  colors={'noswitch': 'red', 'switch': 'blue', 'switch-noswitch': 'black'},
  picks=FCz,show=False,invert_y=True)
plt.rcParams.update({'font.size': 22})
fig.set_size_inches(7,3)

times = [-0.315, 0.150, 0.630]
for t in times:
  plt.axvline(x=t,color='black',linestyle='--')

fig.show()

fig.savefig('../../plots/switch_mean_'+str(datetime.date.today())+'.pdf')

# mne.viz.plot_evoked(evokeds['switch-noswitch'],picks=FCz)

average = mne.set_eeg_reference(evokeds['switch-noswitch'],ref_channels=None)[0]
average.apply_proj()
fig = (-evokeds['switch-noswitch']).plot_topomap(times=times,
                                              show=False)
fig.set_size_inches(9,4)
# plt.show()
fig.savefig('../../plots/switch_mean_topo_'+str(datetime.date.today())+'.pdf')
