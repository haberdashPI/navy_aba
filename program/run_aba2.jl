#!/usr/bin/env julia

# STUDY 2: Continuous ABA- with deviants to (possibly) reset streaming

using Weber
include("calibrate.jl")
include("stimtrak.jl")

version = v"0.1.0"
sid,trial_skip,deviant = @read_args("ABA study",deviant=[:ripple,:flash])

randomize_by(sid * string(deviant))
################################################################################
# settings

const st = 1/12

low = 3st
medium = 6st
high = 18st
medium_str = "6st"

# ABA a stimulus parameters
tone_len = 50ms
tone_SOA = 120ms
aba_SOA = 4tone_SOA
A_freq = 400Hz

# trial composition
n_aba = 100 # per trial
aba_buildup = 20 # on each trila
n_deviants = 8 # per trial
deviant_spacing = 4

# ripple noise parameters
ripple_itr = 7
ripple_freqs = [1kHz, 2kHz, 3kHz]
ripple_highpass = 1kHz
ripple_dB = atten_dB - 5
ripple_ramp = 50ms
ripple_len = 0.5s

n_trials = 30

################################################################################
# experiment and trial definitions

experiment = Experiment(
  columns = [
    :sid => sid,
    :condition => "study2",
    :deviant => string(deviant),
    :version => version,
    :separation => medium_str,
    :stimulus,:stimtrak
  ],
  data_dir=joinpath("..","data","csv"),
  skip=trial_skip,
  # extensions=[@DAQmx(stimtrak_port,codes=stimtrak_codes,eeg_sample_rate=512),
  #             @Cedrus()],
  moment_resolution=moment_resolution,
)

function aba(steps)
  A = ramp(tone(A_freq,tone_len))
  B = ramp(tone(A_freq * 2^steps,tone_len))
  gap = silence(tone_SOA-tone_len)
  aba_ = attenuate([A;gap;B;gap;A],atten_dB)

  [aba_;silence(aba_SOA-duration(aba_))]
end

const an_aba = aba(medium)

a_ripple(f) = @> begin
  irn(ripple_itr,1 / f,ripple_len)
  highpass(ripple_highpass,order=2)
  attenuate(ripple_dB)
  ramp(ripple_ramp)
end

const ripples = [a_ripple(f) for f in ripple_freqs]
n_ripple_repeats = ceil(Int,n_deviants*n_trials/3)
const ripple_order = shuffle(repeat(1:length(ripples),inner=n_ripple_repeats))

isresponse(e) = iskeydown(e,stream_1) || iskeydown(e,stream_2)

function a_trial(trial_num)
  resp = response(stream_1 => "stream_1",stream_2 => "stream_2")
  count = 0
  stim = oddball_paradigm(n_deviants,n_aba - n_deviants,
                          lead = aba_buildup,
                          oddball_spacing = deviant_spacing) do isdeviant
    if isdeviant
      if deviant == :flash
        [moment(aba_SOA,play,an_aba),
         moment(display,visual(colorant"red",duration=300ms))]
      elseif deviant == :ripple
        ripple_index = ripple_order[trial_num+count]
        count += 1
        [moment(aba_SOA,play,mix(an_aba,ripples[ripple_index])),
         moment(record,"ripple",value=ripple_index)]
      else
        error("Unexpected deviant type $deviant")
      end
    else
      [show_cross(),moment(aba_SOA,play,an_aba)]
    end
  end

  abreak = [moment(display,"Hit space to start next trial."),
            await_response(iskeydown(end_break_key))]

  [resp,stim,abreak]
end

################################################################################
# instructions and trial setup

setup(experiment) do
  addbreak(moment(250ms,play,@> tone(1kHz,1s) ramp attenuate(atten_dB)))
  anykey = moment(display,"Hit any key to start the experiment...")
  addbreak(anykey,await_response(iskeydown))

  for trial_num in 1:n_trials
    if trial_num == 1
      marker = moment(record,"experiment_start")
    else
      marker = moment()
    end

    addtrial(marker,a_trial(trial_num))
  end
end

run(experiment)
