# About

This is a work-in-progress experiment looking at
[auditory streaming](http://www.nature.com/nrn/journal/v14/n10/fig_tab/nrn3565_F3.html)
with intermittent presentations, to allow for easier to interpret EEG data,
motivated by the following work:

Pitts, M. A., & Britz, J. (2011). Insights from Intermittent Binocular Rivalry and EEG. Frontiers in Human Neuroscience, 5. https://doi.org/10.3389/fnhum.2011.00107

# Installation

You need to install julia, and then run the setup.jl script.

One way to do this is as follows:

1. [Download](https://github.com/haberdashPI/navy_wordstream/archive/master.zip)
   and unzip this project.
2. Follow the directions to [install Juno](https://github.com/JunoLab/uber-juno/blob/master/setup.md)
3. Open the setup.jl file for this project in Juno.
4. Run setup.jl in Juno (e.g. Julia > Run File).
5. call `using Weber` to verify the installation (you may need to restart Julia).

# Running

If you installed Juno (see above) just run `run_aba.jl` in Juno.  Make
sure you have the console open (Julia > Open Console), as you will be prompted
to enter a number of experimental parameters. Also note that important warnings
and information about the experiment will be written to the console.

Alternatively, if you have julia setup in your `PATH`, you can run the
experiment from a terminal by typing `julia run_aba.jl`. On mac (or unix)
this can be shortened to `./run_aba.jl`. You can get help about how to
use the console verison by typing `julia run_aba.jl -h` (or `./run_aba.jl` on
mac or unix).

## Restarting the experiment

If the experiment gets interrupted, the program will report an offset
number. This number is also saved on each line of the data recorded during
the experiment. You can use this number to call `run_aba.jl` starting from
somewhere in the middle of the experiment.

