function eeg2 = copyica(eeg1,eeg2)
  eeg2.icaact = eeg1.icaact;
  eeg2.icasphere = eeg1.icasphere;
  eeg2.icaweights = eeg1.icaweights;
  eeg2.icachansind = eeg1.icachansind;
  eeg2.icasplinefile = eeg1.icasplinefile;
  eeg2.icawinv = eeg1.icawinv;
end


