%% ----------------------------------------------------------------------------
eeglab;

%% ----------------------------------------------------------------------------
%% files
data_dir = '/Volumes/MiguelJr/Research/Data/navy_aba/study1/';
proj_dir = '/Users/davidlittle/MEGA/Research/software/navy_aba/';
binlist_result_file = [proj_dir 'analysis/binlest_test.txt'];

names = {...
  ...% '1101_4-21-17',...
  '1102_2017_04_24',...
  '1103_2017_04_24',...
  ...% 1104 had no switches (and had artificial hair); her data was lost
  ...%'1105_2017_04_26',... % only 18 switches
  '1106_5-1-17',...
  ...%'1107_5-2-2017',...   % no switches
  '1108_05_03_2017',...
  '1109_05_05_2017',...
  '1110_05_08_2017',...
  '1111_05_10_2017',...
  '1112_05_11_2017',...
  '1113_05_11_2017',...
  '1114_05_12_2017',...
  'anthony_04_18_17',...
  'Beatriz_03_20_17',...
  'Jacki_03_22_17',...
  'Jared_04_03_17',...
  'jessica_2017_04_07',...
  'sandra_2017_03_31'...
}

%% ----------------------------------------------------------------------------
%% ica processing

% TODO: split out the switching bins (and any other conditions except
% stream12).
% after manual ICA removal, parse the spreadsheet, and apply
% the components to all conditions in a second, automated step.

for i = 1:length(names)
  name = names{i};
  parts = split(name,'_');
  base_name = parts{1};

  bdf_file = [data_dir 'bdf/' name '.bdf'];
  event_file = [data_dir  'events/' base_name '_clean_events.txt'];
  channel_loc_file = [data_dir '../acnlbiosemi64.elp'];
  result_file = [data_dir 'eeglab/' base_name '_stream12_ica.set']
  switching_binlist = [proj_dir 'analysis/switching_binlist.txt'];
  stream12_binlist = [proj_dir 'analysis/stream12_binlist.txt'];
  if exist(result_file) ~= 0
    disp(["Skpping, the file '" result_file "', because it already exists."]);
    continue;
  end

  eeg = pop_fileio(bdf_file);
  eeg = pop_importevent(eeg, 'append','no','event',event_file,...
    'fields',{'latency' 'type'},'skipline',1,'timeunit',1);
  eeg = pop_editset(eeg, 'chanlocs', channel_loc_file);

  eeg = pop_creabasiceventlist( eeg , 'AlphanumericCleaning', 'on', ...
                                     'BoundaryNumeric', { -99 },...
                                     'BoundaryString', { 'boundary' } );
  eeg  = pop_basicfilter(eeg,  1:72 , 'Cutoff', [ 0.01 30.0],...
                              'Design', 'butter', ...
                              'Filter', 'bandpass');

  stream12_epochs  = pop_binlister(eeg, 'BDF', stream12_binlist);
  stream12_epochs = pop_epochbin(stream12_epochs, [-200.0  2800.0], 'pre');
  switching_epochs = pop_binlister(eeg, 'BDF', switching_binlist);
  switching_epochs = pop_epochbin(switching_epochs,[-3000.0 2800.0],[-200, 0]);

  % reject truly wild artifacts
  stream12_epochs = pop_artmwppth(stream12_epochs, 'channel', 1:72, 'flag',...
    1, 'threshold',  350, 'twindow', [ -199.2 2798.8], 'windowsize',  100,...
    'windowstep', 50);
  switching_epochs = pop_artmwppth(switching_epochs, 'channel', 1:72, 'flag',...
    1, 'threshold',  350, 'twindow', [ -2999.0 2798.8], 'windowsize',  100,...
    'windowstep', 50);

  % run ica
  stream12_epochs = pop_runica(stream12_epochs,'extended',1,'icatype',...
    'binica','chanind',1:72);
  % copy ica results to switching epochs
  switching_epochs = copyica(stream12_epochs,switching_epochs);

  % save results
  pop_saveset(stream12_epochs,'filename',[base_name '_stream12_ica.set'],...
    'filepath',[data_dir 'eeglab/']);
  pop_saveset(switching_epochs,'filename',[base_name '_switching_ica.set'],...
    'filepath',[data_dir 'eeglab/']);
end

%% MANUAL STEP
% Before running the next block, each set of ica components must be examined.
%
% Open eeglab and load a file with suffix '_stream12_ica.set'. Run ADJUST, and
% reject any components ADJUST rejects that don't look like they have any
% signal in them (i.e. a flat specturm). Real artificats should be distributed
% throughout the channels and time.  Also make sure that there aren't any
% obvious artifacts that ADJUST missed in the first few components.  Once the
% components have been selected for rejection, reject them and verify that they
% worked by comparing the old and new raw data to make sure artifacts were
% removed and no weird noise was introduced by component rejection.

% Save the resulting eeg to a new file in the same directory with the suffix
% '_stream12_ica_rej.set'
% Then, reject the same components for the file with suffix '_switching_ica.set'
% and then re-verify the raw data for this version.

%% ----------------------------------------------------------------------------
%% epoching/averaging

for i = 1:length(names)
  name = names{i}
  parts = split(name,'_')
  base_name = parts{1}

  epochs = pop_loadset('filename',[base_name '_stream12_ica_rej.set'],...
    'filepath',[data_dir 'eeglab/']);

  % reject remaining artifacts
  epochs = pop_artmwppth(epochs, 'Channel',  1:72, 'Flag',  1, 'Threshold',  150, ...
                      'Twindow', [ -199.2 2798.8], 'Windowsize',  100,...
                      'Windowstep',  50 this is a test);

  % average
  erp = pop_averager( epochs , 'Criterion', 'good', 'ExcludeBoundary', 'on',
                      'SEM', 'on' );

  % re-reference to mastoids
  ops = {}
  for i in 1:71
    ops{i} = ['nch' num2str(i) ' = ch' num2str(i) ...
              ' - ( (ch65 + ch66)/2 ) Label' eeg.chanlocs(i).labels]
  end
  erp = pop_erpchanoperator( erp, ops );

  erp = pop_savemyerp(erp, 'filename', base_name '_stream12_ica_M12.erp', ...
                      'filepath', [data_dir 'eeglab/']);
end
