#!/usr/bin/env julia

# STUDY 2: Continuous ABA- with deviants to reset streaming

using Weber
include("calibrate.jl")
include("stimtrak.jl")

version = v"0.0.1"
sid,trial_skip,deviant = @read_args("ABA study",deviant=[:gap,:surprise_tone])

################################################################################
# settings

const st = 1/12

low = 3st
medium = 6st
high = 18st
medium_str = "6st"

tone_len = 50ms
tone_SOA = 120ms
aba_SOA = 4tone_SOA
A_freq = 400Hz

aba_per_trial = 100
aba_buildup = 20
deviants_per_trial = 8

n_trials = 30

n_repeat_example = 20

################################################################################
# experiment and trial definitions

experiment = Experiment(
  columns = [
    :sid => sid,
    :condition => "study2",
    :version => version,
    :separation => medium_str,
    :stimulus,:stimtrak
  ],
  data_dir=joinpath("..","data","csv"),
  skip=trial_skip,
  extensions=[@DAQmx(stimtrak_port,codes=stimtrak_codes,eeg_sample_rate=512),
              @Cedrus()],
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
const surprise_tone = @> tone(2kHz,1s) ramp attenuate(atten_dB - 5)

isresponse(e) = iskeydown(e,stream_1) || iskeydown(e,stream_2)

function a_trial()
  resp = response(stream_1 => "stream_1",stream_2 => "stream_2")
  deviant_indices = shuffle(aba_buildup:aba_per_trial)[1:deviants_per_trial]

  stim = map(1:aba_per_trial) do i
    if i in deviant_indices
      if deviant == :gap
        moment(aba_SOA)
      elseif deviant == :surprise_tone
        moment(aba_SOA,play,mix(an_aba,surprise_tone))
      end
    else
      moment(aba_SOA,play,an_aba)
    end
  end

  [resp,stim]
end

################################################################################
# instructions and trial setup

setup(experiment) do
  addbreak(moment(250ms,play,@> tone(1kHz,1s) ramp attenuate(atten_dB)))

  anykey = moment(display,"Hit any key to start the experiment...")
  addbreak(anykey,await_response(iskeydown))

  for trial in 1:n_trials
    if trial == 1
      marker = moment(record,"experiment_start")
    else
      marker = moment()
    end

    addtrial(marker,a_trial())
  end
end

run(experiment)
