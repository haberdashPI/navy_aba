% ------------------------------------------------
eeglab;

% ------------------------------------------------------------------------------
% files
data_dir = '/Volumes/MiguelJr/Research/Data/navy_aba/study1/';
proj_dir = '/Users/davidlittle/MEGA/Research/software/navy_aba';
binlist_file = [proj_dir 'analysis/binlist.txt'];
binlist_result_file = [proj_dir 'analysis/binlest_test.txt'];

names = {
  '1101_4-21-17.bdf',
  '1102_2017_04_24.bdf',
  '1103_2017_04_24.bdf',
  '1105_2017_04_26.bdf',
  '1106_5-1-17.bdf',
  '1107_5-2-2017.bdf',
  '1108_05_03_2017.bdf',
  '1109_05_05_2017.bdf',
  '1110_05_08_2017.bdf',
  '1111_05_10_2017.bdf',
  '1112_05_11_2017.bdf',
  '1113_05_11_2017.bdf',
  '1114_05_12_2017.bdf',
  'anthony_04_18_17.bdf',
  'Beatriz_03_20_17.bdf',
  'Jacki_03_22_17.bdf',
  'Jared_04_03_17.bdf',
  'jessica_2017_04_07.bdf',
  'sandra_2017_03_31.bdf'
}

% ------------------------------------------------------------------------------
% ica processing

for name = names
  parts = split(name,'_')
  base_name = parts{1}

  bdf_file = [data_dir 'bdf/' name '.bdf'];
  event_file = [data_dir  'events/' base_name '_clean_events.txt'];
  channel_loc_file = [data_dir '../acnlbiosemi64.elp'];

  eeg = pop_fileio(bdf_file);
  eeg = pop_importevent(eeg, 'append','no','event',event_file,...
    'fields',{'latency' 'type'},'skipline',1,'timeunit',1);
  eeg = pop_editset(eeg, 'chanlocs', channel_loc_file);

  eeg = pop_rejchan(eeg, 'elec',[1:74] ,'threshold',6,'norm','on','measure','kurt');
  eeg = pop_creabasiceventlist( eeg , 'AlphanumericCleaning', 'on', ...
                                     'BoundaryNumeric', { -99 },...
                                     'BoundaryString', { 'boundary' } );
  eeg  = pop_basicfilter(eeg,  1:72 , 'Cutoff', [ 0.01 30.0],...
                              'Design', 'butter', ...
                              'Filter', 'bandpass');

  epochs  = pop_binlister(eeg , 'BDF', binlist_file, 'ExportEL', ...
                          binlist_result_file, 'IndexEL',  1, 'SendEL2', 'EEG&Text');
  epochs = pop_epochbin( epochs , [-200.0  2800.0],  'pre');

  epochs = pop_runica(epochs, 'extended',1);
  pop_saveset( epochs, 'filename',[base_name '_stream12_ica_M12.set'],'filepath',[data_dir 'eeglab/']);
end
% ------------------------------------------------------------------------------
% epoching/averaging

eeg  = pop_artmwppth(eeg, 'Channel',  1:71, 'Flag',  1, 'Threshold',  150, ...
                     'Twindow', [ -199.2 2798.8], 'Windowsize',  100,...
                     'Windowstep',  50 this is a test);

% average
ERP = pop_averager( EEG , 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on' );

% re-reference to mastoids
ops = {}
for i in 1:71
  ops{i} = ['nch' num2str(i) ' = ch' num2str(i) ' - ( (ch65 + ch66)/2 ) Label' EEG.chanlocs(i).labels]
end
ERP = pop_erpchanoperator( ERP, ops );

ERP = pop_savemyerp(ERP, 'filename', '1101_stream12_ica_M12.erp', 'filepath', '/Users/davidlittle/Desktop');
