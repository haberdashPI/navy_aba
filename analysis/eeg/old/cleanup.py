import sys
import os
import os.path as op
import numpy as np
import mne
execfile("local_settings.py")

bdf_dir = op.join(data_dir,"bdf")

# the location for all intermediate processing stages
# (put in a temporary directory)

for name in names:
  if op.isfile(op.join(temp_dir,name+".fif")):
    print op.join(temp_dir,name+".fif")+" already generated, skipping..."
    continue
  print "Processing ",name
  raw = mne.io.read_raw_edf(op.join(bdf_dir,name+".bdf"),
                            preload=True,misc=['Erg1'],
                            eog=['IO1','IO2','LO1','LO2'],
                            montage=op.join(data_dir,'..','acnlbiosemi64.sfp'))

  raw.filter(0.01,30,l_trans_bandwidth='auto',
             h_trans_bandwidth='auto',
             filter_length='auto',phase='zero')

  mne.set_eeg_reference(raw,copy=False,ref_channels=['M1','M2'])
  raw.save(op.join(temp_dir,name+".fif"))
