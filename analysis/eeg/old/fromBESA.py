import sys
import os
import os.path as op
import numpy as np
import mne
import matplotlib.pyplot as plt
import re
from copy import deepcopy
execfile("local_settings.py")

data_dir = op.realpath(op.join("..","..","data"))
besa_dir = "/Volumes/MiguelJr/Research/Data/navy_aba/study1/edf_cleaned"

name = "Jared_04_03_17"

# raw = mne.io.read_raw_edf(op.join(besa_dir,name+".bdf"),preload=True,
#                           misc=['Erg1'],eog=['IO1','IO2','LO1','LO2'],
#                           montage=op.join(data_dir,'acnlbiosemi64.sfp'))


array_file = op.join(besa_dir,name+"-export.dat")
montage = mne.channels.read_montage(op.join(data_dir,"acnlbiosemi64.sfp"))
names = deepcopy(montage.ch_names)
names.append('ERG1')
names.append('STATUS')
names.append('heog')
names.append('veog')
ixs = np.arange(74)
info = mne.create_info(
  ch_names = names,
  ch_types = np.hstack([np.repeat('eeg',72),np.repeat('misc',4)]),
  sfreq = 512
)

data = np.fromfile(array_file,dtype='float32')
rdata = np.reshape(data,(76,data.size/76),order='C')
raw = mne.io.RawArray(rdata,info)

# for name in names:
#name = "1103_2017_04_24"

# for name in names:
  # result_file = op.join(temp_dir,name+"_cleaned.fif")
#   if op.isfile(result_file):
#     print result_file," already generated, skipping..."
#     continue

#   raw = mne.io.read_raw_edf(op.join(besa_dir,name+"_clean.edf"),
#                             misc=['P STATUS','P ERG1'],
#                             preload=True)

#   def clean_name(name):
#     name = re.sub(r"(\w+)_mast", r"\1",name)
#     name = re.sub(r"E (\w+)-Ref", r"\1",name)
#     name = re.sub(r"P (\w+)", r"\1",name)
#     return name

#   new_names = dict((name,clean_name(name)) for name in raw.info['ch_names'])
#   mne.rename_channels(raw.info,new_names)

#   raw.set_montage(mne.channels.read_montage(op.join(data_dir,"acnlbiosemi64.sfp")))
#   raw.filter(l_freq=0.01,h_freq=30)

#   raw.save(result_file)
