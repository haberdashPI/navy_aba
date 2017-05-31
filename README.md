# About

This is a work-in-progress experiment looking at
[auditory streaming](http://www.nature.com/nrn/journal/v14/n10/fig_tab/nrn3565_F3.html)
with intermittent presentations, ala
[Pitts & Britz (2011)](https://doi.org/10.3389/fnhum.2011.00107).

# Contents

* [Running the experiment](running-the-experiment)
* [Data analysis](data-analysis)

# Running the experiment

You need to install julia, run the setup.jl script, and then run the appropriate study.

To install the expeirment:

1. [Download](https://github.com/haberdashPI/navy_wordstream/archive/master.zip)
   and unzip this project.
2. Follow the directions to [install Juno](https://github.com/JunoLab/uber-juno/blob/master/setup.md)
3. Open the setup.jl file for this project in Juno.
4. Run setup.jl in Juno (e.g. Julia > Run File).
5. call `using Weber` to verify the installation (you may need to restart Julia).

To run the experiment:

1. Open Juno
2. Open the console (Julia > Open Console)
3. Change the working directory to the `program` folder - to do this open a file
in that folder, then go to the menu itme Julia > Working Directory > Current
File's Folder.
3. To run the first study type `include("run_aba.jl")` and hit enter.

Replace `run_aba.jl` with whatever study you want to actually run. All study files
are prefixed with `run_`. Any other Julia files are referenced somewhere in the
study files.

## Restarting the experiment

If the experiment gets interrupted, the program will report an offset
number. This number is also saved on each line of the data recorded during
the experiment. You can use this number to call `run_aba.jl` starting from
somewhere in the middle of the experiment.

# Data analysis

To re-run the analyses, you will need:

* [R](https://www.r-project.org/)
* [RStudio](https://www.rstudio.com/)
* [anaconda (pythong 2.7)](https://www.continuum.io/downloads)
* [Matlab](https://www.mathworks.com/)
* [eeglab](https://sccn.ucsd.edu/eeglab/)

Install all of these programs before proceeding. 

Before running the analysis, you must first place all of the raw BDFs (which are
not part of the git repository) in a folder named `eeg_data`, located directly
under the base folder (`navy_aba`).

## Power Analysis

A simple power analysis using [Davidson and Pitts (2014)](**TODO**) can be found
in `analysis/eeg/power`. When running this code in R, the `pwr.t.test` calls
will report the estaimtes for N. This file also includes a work-in-progress
desing anlaysis based on the methods described in [Gelman and Carlin (2014)](**TODO**). 

## Analysis of EEG

### Extrating events from the raw EEG files

The first step for eeg anlaysis is extracting the events from the bdfs. This
process will create an event file that can be loaded in BESA research, and
another that can be loaded in eeglab. This can
be done as follows:

1. Open Spyder - this should be installed with anaconda.
2. Open `analysis/eeg/extract_events.py`
3. Set the current working directory of python to be `anlaysis/eeg` - you can do
   this by right clicking the tab for `extract_events.py` and selecting the
   appropriate command.
4. Run `analysis/eeg/extract_events.py`
5. Open RStudio
6. Open `analysis/eeg/clean_events.R`
7. Set the current working directory of R to be `analysis/eeg` - you can do this
   by **TODO**.
8. Set the current 

From this point, once you hvae extracted events there are two working approaches
for extracting ERPs.

### finding ERPs in BESA

**TODO**: move the various BESA batch files and paradigm files into this folder,
and re-run anlayses to verify this process works.

### finding ERPs in eeglab

**TODO**: finish up this pipeline, verify it, and write up the directions here.

## Analysis of Behavior

Each files under `analysis/behavior` generates several different plots (written
to the `plots` folder). Before running these, you must extra
[events from the eeg files](extracting-events-fromthe-raw-eeg-files). Once
you've extracted events you can open any of the behavioral anlaysis files in R
and run them (from the `analysis/behavior`) to re-generate graphs (or add new
participants after collecting further data). Each file contains a description of
the graphs it produces **TODO**.
