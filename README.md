# About

This project is a work-in-progress experiment looking at
[auditory streaming](http://www.nature.com/nrn/journal/v14/n10/fig_tab/nrn3565_F3.html)
with intermittent presentations, ala
[Pitts & Britz (2011)](https://doi.org/10.3389/fnhum.2011.00107).

# Contents

* [Guide](#guide)
* [Running the experiment](#running-the-experiment)
* [Data analysis](#data-analysis)

# Guide

This README.md provides a guide to collecting and analyzing data as
has been performed so far.

Where relative folders are identified (e.g. `eeg_data/bdf`) these folder
locations are in reference to the base directory, where this `README.md` file is
located.

## Version Control

This project is organized and managed using [git](https://git-scm.com/),
for verison control. Version control allows you to mark changes
as you make them to files, with notes that describe what you changed and why.
You can then peruse this history and retrieve previosuly
saved versions of any file.

All of the EEG data, and files derrived thereof should be excluded from
version control (because the files are so large), and should be
stored under `eeg_data`. Any instructions for recreating the processed
eeg files are contained in this README.md, so to retrieve a specific version
of the EEG analysis, the hope is that one need only follow the directions below
(under [data anlaysis](#data-analysis)).

# Running the experiment

You need to install Julia, run the setup.jl script, and then run the appropriate study.

To install the expeirment:

1. [Download](https://github.com/haberdashPI/navy_wordstream/archive/master.zip)
   and unzip this project.
2. Follow the directions to
   [install Juno](https://github.com/JunoLab/uber-juno/blob/master/setup.md)
3. Open the setup.jl file for this project in Atom.
4. Run setup.jl in Atom (e.g. Julia > Run File).
5. call `using Weber` to verify the installation (you may need to restart Julia).

To run the experiment:

1. Open Atom
2. Open the console (Julia > Open Console)
3. Change the working directory to the `program` folder - to do this open a file
in that folder, then go to the menu itme Julia > Working Directory > Current
File's Folder.
3. To run the first study type `include("run_aba.jl")` and hit enter.

Replace `run_aba.jl` with whatever study you want to actually run. All study
files are prefixed with `run_`. Any other Julia files are referenced somewhere
in the study files.

## Restarting the experiment

If the experiment gets interrupted, the program will report an offset
number. This number is also saved on each line of the data recorded during
the experiment. You can use this number to call `run_aba.jl` starting from
somewhere in the middle of the experiment.

# Data analysis

The follow section provides directions to reproduce the work-in-progress
analysis.

We have been using BESA for meetings because it is quick and fast to
run, and allows us to perform sanity checks as we collect subjects. (Are we
collecting good data? Does it even make sense?)

In the background we have also been working on an eeglab analysis. The eeglab
anlaysis has been performed with a few goals in mind:

1. To learn how to use other tools and get familiar with ICA anlaysis.
2. It's easier for me personally to code than to sit and use a GUI
and the more advanced analyses we'd like to do are easier to script than
to run manually in BESA.
3. I have been hoping to calculate measurement errors for each participant so
that a more modern power analysis can be applied to the data.

So far only goal 1 has really come to fruition: the more advanced analysis
and the power analysis have yet to be completed (since we're still working on
removing ICA components in eeglab).

## Installation and Setup

To re-run the analyses, you will need:

* [R](https://www.r-project.org/)
* [RStudio](https://www.rstudio.com/)
* [anaconda (python 2.7)](https://www.continuum.io/downloads)

And either:

* [Matlab](https://www.mathworks.com/)
* [eeglab](https://sccn.ucsd.edu/eeglab/)

Or:

* [BESA Research](http://www.besa.de/)

Install these programs before proceeding. You will also need to run
`analysis/setup.py` and `analysis/setup.R`. To do so, follow these directions:

To run `setup.py`:
1. Open Spyder - this should be installed with anaconda.
2. Open `analysis/setup.py`
3. Set the current working directory of python to be `anlaysis` - you can do
   this by right clicking the tab for `setup.py` and clicking
   "Set console working directory".
4. Run `analysis/setup.py` (using the green play button)

To run `setup.R`
1. Open RStudio
2. Open `analysis/setup.R`
3. Set the current working directory of R to be `analysis` - you can do this
   by selecting Session > Set Working Directory > To Source File Location.
4. Run `setup.R` - you can do this by clicking Source on the upper right
   part of the window showing `setup.R`.

Finally, you must first place all of the raw BDFs (which are
not part of this git repository) in a folder named `eeg_data/bdf`.
In the ACNLab, these files are located on both CUMIN (under
`C:\Users\ACNLab\Documents\navy_aba\eeg_data`) and on PEPPER
(under `C:\Users\ACNLab\Desktop\EEG Data - Shortcut\NAVY_aba`).

> The existing anlayses assume you are analyzing `study1`.
> You will need to make changes to `local_settings.py` and `local_settings.R`
> and replace any other references to `study1` with the name of your followup
> study.

## Power Analysis

A simple power analysis using effect sizes from
[Davidson and Pitts (2014)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4126364/)
can be found in `analysis/eeg/power`. When running this code in R,
the `pwr.t.test` calls will report the estaimtes for N. This file also includes
a work-in-progress design anlaysis based on the methods described in
[Gelman and Carlin (2014)](http://www.stat.columbia.edu/~gelman/research/published/retropower_final.pdf).

## Analysis of EEG

### Extracting events from the raw EEG files

The first step for eeg anlaysis is extracting the events from the bdfs. This
process will create an event file that can be loaded in BESA research, and
another that can be loaded in eeglab. To do so, run
`analysis/eeg/extract_events.py` and `analysis/eeg/clean_events.R`.
Read the directions above under [installation and setup](installation-and-setup)
for running `setup.py` and `setup.R` for how to run scripts in python and R.

Once you have extracted events, there are two working approaches for finding ERPs.

### Finding ERPs in BESA

First, copy all of the raw BDF's, and all evt files into a new folder called
`eeg_data/study1/BESA`. Do not copy any participant data that you do not
want to include (see `data/participant_notes.md`). This approach keeps
the original bdf's from being mixed in with all of the temporary files
BESA creates. Furthermore, it avoids *any* modification of these origianl BDF
files by BESA. The event files are copied over to simplify batch processing.

In the present anlaysis we have excluded any participant with a low proportion
of switches (< 20). The list of excluded participants is noted in
`analysis/local_settings.py`.

#### Calculating the individual averages

To find the ERPs for each individual listener:

1. Open BESA Reserach
2. Go to Process > Run Batch...
3. Add all files in `eeg_data/study1/BESA` to the File List.
4. Change tabs and click `Load Batch`
5. Select `analysis/eeg/BESA/study1_2017_05_31.bbat`.
6. You will probably need to repsecify the location of the paradigm file
   `analysis/eeg/BESA/study1_2017_04_27.PDG`. To do so
   right click the line startign with "MAINParadigm(...", click
   "Edit Command" then "Browser..." and then select the paradigm file.
7. Click "Ok"

The batch run will take some time to complete. Go find some other work to do.

#### Calculating the grand averages

To find a grand average ERP:

1. Open BESA Research
2. Go to ERP > Combine Conditions, Channels, Find Peaks
3. Use "Add File" to add files under `eeg_data/study1/BESA/` with the `fsg`
extension that you desire to average.
4. Add a `stream2 - stream1` and a `switch - noswitch` target condition under
"Condition List".
5. Go to the "Run Script" tab and click "OK".

### Finding ERPs in eeglab

The work in progress eeglab anlayis is located in `preprocess.m`. The idea is
that you cut and past parts of this script to run in MATLAB. The working
directory of matlab should be the same as the location of this README file. The
code up to the ica processing step is working and can be used to generate
filtered, epoched data with computed ICA components. It takes about 4 hours
to run on the current 19 participants using my machine.

The goal is to then select components to be rejected (in the resulting
`eeg_data/study1/eeglab/[sid]_stream12_ica`), save the results, and then
have the script use those components to generate any means we desired.

Note: I've written a function called `copyica` to transfer a set of calculated
components from one set of epochs to another. My plan is to use that to use
the ICA components calculated using the `stream12` epcohs to correct for
eyeblinks in the `switching` epochs.

### Finding ERPs with python MNE

There is an incomplete, almost working analysis of the EEG data in
[python-mne](https://martinos.org/mne/stable/index.html) under
`anlaysis/eeg/old`. What remains to get this working completely is better
rejection of artifacts. This should be possible following a procedure similar to
that described for eeglab. It is faster and has a better programming interface
than eeglab, and has a number of source analysis methods that I believe eeglab
lacks. However, it's documentation is much worse. Good luck!

## Analysis of Behavior

Each files under `analysis/behavior` generates several different plots (written
to the `plots` folder). Before running these, you must extra
[events from the eeg files](extracting-events-fromthe-raw-eeg-files). Once
you've extracted events you can open any of the behavioral anlaysis files in R
and run them (from the `analysis/behavior`) to re-generate graphs (or add new
participants after collecting further data). Each file contains a description of
the graphs it produces.
