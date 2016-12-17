# About

This is a work-in-progress expeirment looking at
[auditory streaming](http://www.nature.com/nrn/journal/v14/n10/fig_tab/nrn3565_F3.html)
with intermittent presentations, to allow easier to interpret EEG data,
motivated by the following research:

Pitts, M. A., & Britz, J. (2011). Insights from Intermittent Binocular Rivalry and EEG. Frontiers in Human Neuroscience, 5. https://doi.org/10.3389/fnhum.2011.00107

# Installation

1. [Download](https://github.com/haberdashPI/navy_aba/archive/master.zip)
   and unzip this project.
2. Install the 64-bit version of
   [julia](https://en.wikibooks.org/wiki/Introducing_Julia/Getting_started)
   (make sure julia is in your `PATH`)
3. Run setup.jl

This last step is accomplished by entering the following commands in a terminal.

```console
$ cd "[download-location]"
$ julia setup.jl
```

Replace `[download-location]` with the directory where you unziped this project.

# Running

To run the experiment just call julia from the terminal as follows:

```console
$ cd "[download-location]"
$ julia run_aba.jl [sid]
```

Replace `[sid]` with a subject id number. Results will be saved in a `data` subdirectory.

## Restarting the experiment

If the experiment gets interrupted, the program will report an offset
number. This number is also saved on each line of the data recorded during
the experiment. You can use this number as a second argument to run_aba.jl,
and the experiment will start at the beginning of the trial it was interrupted
on.

In the below example, the experiment was terminated for participant 1234 at
offset 20, and the experiment is then resumed with the second command.

```console
$ julia run_aba.jl 1234
INFO: Experiment terminated at offset 20.
$ julia run_aba.jl 1234 20
```

