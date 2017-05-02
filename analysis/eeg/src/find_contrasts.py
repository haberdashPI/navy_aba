import pandas as pd
import numpy as np
import os.path as op
import mne
import collections

def find_contrasts(names,stim_files,contrasts,**params):
  contrast_labels = {}
  for i,key in enumerate(contrasts.keys()):
    contrast_labels[key] = 2**i

  evoked = collections.defaultdict(list)
  coverage = collections.defaultdict(list)
  counts = collections.defaultdict(list)

  for name,stim in zip(names,stim_files):
    events = pd.read_table(op.join(temp_dir,stim))
    events['samples'] = np.floor(events.Tmu * 1e-6 * 512)
    events['dummy'] = 0
    events['contrasts'] = 0
    for i,vals in enumerate(contrasts.values()):
      events['contrasts'] += (2**i)*events['TriNo'].isin(vals)

    event_mat = events[['samples','dummy','contrasts']].as_matrix().astype('int_')
    raw = mne.io.read_raw_fif(op.join(temp_dir,name+"_noblink.fif"))
    picks = mne.pick_types(raw.info,eeg=True)

    epochs = mne.Epochs(raw,event_mat,event_id = contrast_labels,
                        reject=dict(eeg=150e-6),picks=picks,**params)

    means = {}
    for key,val in contrast_labels.items():
      means[key] = epochs[key].average()
      N = (event_mat[:,2] == contrast_labels[key]).sum()
      percent = (float(means[key].nave) / N)
      print "%2.1f%% of %s kept" % (100*percent,key)
      coverage[key].append(percent)
      counts[key].append(N)

    for key,val in means.items():
      evoked[key].append(val)

    keys = list(means.keys())
    for i in range(len(keys)-1):
      for j in range(i+1,len(keys)):
        a = keys[i]
        b = keys[j]
        ab = mne.combine_evoked([evoked[a][-1],evoked[b][-1]],[1,-1])
        print "Working on: ",a+' - '+b
        evoked[a+' - '+b].append(ab)

  grand_average = {}
  for key,val in evoked.items():
    grand_average[key] = mne.grand_average(val)

  return dict(ind=evoked,mean=grand_average,coverage=coverage,counts=counts)
