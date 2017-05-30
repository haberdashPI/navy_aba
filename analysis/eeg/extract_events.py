import sys
import os
import os.path as op
import numpy as np
import pandas as pd
import mne

from scipy.signal import butter, filtfilt

execfile("local_settings.py")
execfile("src/astimed.py")
execfile("src/findpeak.py")

manual_offset = {
  "Jared": 0,
  "sandra": 0,
  "Jacki": 0,
  "Beatriz": 0,
  "anthony": 0,
  "jessica": 0,
  "1103": -255,
  "1102": 0,
  "1101": 0,
  "1105": 0,
  "1106": 0,
  "1107": 0,
  "1108": 0,
  "1109": 0,
  "1110": 0,
  "1111": 0,
  "1112": 0,
  "1113": 0,
  "1114": 0
}

codes = np.array([-2**12,-2**13,255+9,9,2**16])
tolerances = np.array([300,300,5,5,1000])

# TODO: skip already analyzed files

for name in names:
  event_file = op.join(data_dir,"events",name+"_events.csv")
  if op.isfile(event_file):
    print event_file+" already generated, skipping..."
    continue

  raw = mne.io.read_raw_edf(op.join(data_dir,"bdf",name+".bdf"),preload=True,misc=['Erg1'],
                            eog=['IO1','IO2','LO1','LO2'],
                            montage=op.join(data_dir,'..','acnlbiosemi64.sfp'))

  # analyze STI channel
  stim_channel = [raw.info['ch_names'].index('STI 014')]

  ## there's an aribtrary offset (from run to run) we need to remove to find the
  ## codes. Sometime the automatic process of finding the offset doesn't work
  ## (usually because there are too many stimulus triggers, and that becomes the
  ## median).
  raw_stim = raw.get_data(picks=stim_channel)
  offset = np.median(raw_stim) + manual_offset[name.split("_")[0]]
  raw_stim = (raw_stim - offset).astype('int_')

  near = np.abs(raw_stim - codes[:,np.newaxis]) < tolerances[:,np.newaxis]
  stims = astimed(1*near[0,:] + 2*near[1,:] + 3*near[2,:] + 3*near[3,:] + 4*near[4,:],512)
  code_names = np.array(['off','button1','button2','trial_start','block_start'])

  run_events = pd.DataFrame({'time': stims[1], 'event': code_names[stims[0]]})

  # analyze ERG channel
  # TODO: make this work for people other than jared (e.g. Beatriz)
  erg1 = raw.pick_channels(['Erg1'])
  erg1.filter(l_freq=40,h_freq=None,picks=[0],phase='zero')

  x = erg1.get_data()
  y = np.maximum(0,x)

  sample_rate = 512
  b,a = butter(2,5 / (512.0/2), 'low')
  y = filtfilt(b,a,y)

  yd = np.hstack([[[0]],np.diff(y)])
  peaks = findpeaks(np.squeeze(yd),0.99,512*3)

  stim_events = pd.DataFrame({'time': peaks/512.0})
  stim_events['event'] = 'stimulus'

  # plt.plot(np.hstack([x.T/np.max(x),yd.T/np.max(yd)]))
  # for i in peaks:
  #   plt.axvline(x=i,color='red')

  all_events = pd.concat([run_events,stim_events])
  all_events['sid'] = name.split("_")[0]
  all_events = all_events.sort_values('time')
  all_events.to_csv(event_file)

  #
  # FOR LAB: provide a way to add in events consistently after the start
