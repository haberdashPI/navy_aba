#!/usr/bin/env julia

# STUDY 1: Intermittent presentation of ABA- pattern

using Weber
include("stimtrak.jl")
include("calibrate.jl")

version = v"0.3.2"
sid,trial_skip =
  @read_args("Runs an intermittant aba ``experiment, version $version.")

experiment = Experiment(
  columns = [
    :sid => sid,
    :condition => "study1",
    :version => version,
    :stimulus,:phase,:stimtrak
  ],
  data_dir=joinpath("..","data","csv"),
  skip=trial_skip,
  extensions = [@DAQmx(stimtrak_port,codes=stimtrak_codes,eeg_sample_rate=512),
                @Cedrus()],
  moment_resolution=moment_resolution,
)


################################################################################
# settings

const st = 1/12

const stream_1 = key":cedrus5:"
const stream_2 = key":cedrus6:"
const end_break_key = key"`"

low = 3st
medium = 6st
high = 18st

tone_len = 73ms
tone_SOA = 175ms
aba_SOA = 4tone_SOA
A_freq = 400Hz

stimuli_per_response = 3
trial_spacing = aba_SOA

n_trials = 600
num_practice_trials = 12
n_break_after = 75
n_validate_trials = 2n_break_after

n_repeat_example = 20

################################################################################
# experiment and trial definitions

function aba(step,tone_len,tone_SOA,aba_SOA,repeat)
  A = ramp(tone(A_freq,tone_len))
  B = ramp(tone(A_freq * 2^step,tone_len))
  gap = silence(tone_SOA-tone_len)
  aba = attenuate([A;gap;B;gap;A],atten_dB)
  aba_ = [aba;silence(aba_SOA-duration(aba))]
  reduce(vcat,Iterators.repeated(aba_,repeat))
end

stimuli = Dict(:medium => aba(medium,tone_len,tone_SOA,aba_SOA,stimuli_per_response))

isresponse(e) = iskeydown(e,stream_1) || iskeydown(e,stream_2)

# runs an entire trial
function practice_trial(stimulus;limit=trial_spacing,info...)
   resp = response(stream_1 => "stream_1",
                   stream_2 => "stream_2";info...)

  waitlen = aba_SOA*stimuli_per_response+limit
  min_wait = aba_SOA*stimuli_per_response+trial_spacing

  go_faster = visual("Faster!",size=50,duration=500ms,y=0.15,priority=1)
  await = timeout(isresponse,waitlen,atleast=min_wait) do
    display(go_faster)
    record("response_timeout";info...)
  end

  [resp,show_cross(),
   moment(play,stimuli[stimulus]),
   moment(record,"stimulus";info...),
   await]
end

function real_trial(stimulus;limit=trial_spacing,info...)
  resp = response(stream_1 => "stream_1",
                  stream_2 => "stream_2";info...)
  [moment(limit,play,stimuli[stimulus]),
   resp,show_cross(),
   moment(record,"stimulus";info...),
   moment(duration(stimuli[stimulus]))]
end

function validate_trial(stimulus;limit=trial_spacing,info...)
  resp = response(stream_1 => "no_switches",
                  stream_2 => "switches";info...)
  [moment(limit,play,stimuli[stimulus]),
   resp,show_cross(),
   moment(record,"stimulus";info...),
   moment(duration(stimuli[stimulus]))]
end

function myinstruct(str)
  text = visual(str*" (Wait for experimenter to press continue...)")
  m = moment() do
    record("instructions")
    display(text)
  end
  [m,await_response(iskeydown(end_break_key))]
end

################################################################################
# instructions and trial setup

setup(experiment) do
  addbreak(moment(250ms,play,@> tone(1kHz,1s) ramp attenuate(atten_dB)))

  example1 = aba(low,tone_len,tone_SOA,aba_SOA,n_repeat_example)

  addbreak(
    moment(display,joinpath("Images","navy_aba_01.png")),
    await_response(iskeydown(end_break_key)))

  @addtrials let play_example = true
    @addtrials while play_example
      addbreak(
        show_cross(),moment(250ms,play,example1),moment(duration(example1)),
        moment(display,"Again? [Y / N]"),
        response -> play_example = iskeydown(response,key"y"),
        await_response(r -> iskeydown(r,key"y") || iskeydown(r,key"n")))
    end
  end

  addbreak(
    moment(display,joinpath("Images","navy_aba_01.png")),
    await_response(iskeydown(end_break_key)),
    moment(display,joinpath("Images","navy_aba_02.png")),
    await_response(iskeydown(end_break_key)))

  example2 = aba(high,0.75tone_len,0.75tone_SOA,0.75aba_SOA,n_repeat_example)

  addbreak(
    moment(display,joinpath("Images","navy_aba_03.png")),
    await_response(iskeydown(end_break_key)))
  @addtrials let play_example = true
    @addtrials while play_example
      addbreak(
        show_cross(),moment(play,example2),moment(duration(example2)),
        moment(display,"Again? [Y / N]"),
        response -> play_example = iskeydown(response,key"y"),
        await_response(r -> iskeydown(r,key"y") || iskeydown(r,key"n")))
    end
  end

  addbreak(
    myinstruct("""

      In this experiment we'll be asking you to listen for whether it appears
      that the tones "gallop", or not."""),

    myinstruct("""

      Every once in a while, we want you to indicate what you heard most often,
      a gallop or something else. Let's practice a bit.  Use the yellow button
      to indicate that you heard a "gallop" most of the time, and otherwise use
      the orange button.

      """))

  addpractice(
    Iterators.repeated(practice_trial(:medium,phase="practice",
                                      limit=10trial_spacing),
                       num_practice_trials))

  addbreak(myinstruct("""

    In the real experiment, your time to respond will be limited. Let's
    try another practice round, this time a little bit faster.
    """))

  addpractice(
    Iterators.repeated(practice_trial(:medium,phase="practice",
                                      limit=2trial_spacing),
                       num_practice_trials))

  addbreak(myinstruct("""

    During the expeirment, try to respond before the next trial begins, but
    even if you don't, please still respond."""))

  anykey = moment(display,"Hit any key to start the real experiment...")
  addbreak(anykey,await_response(iskeydown))

  total_breaks = div(n_trials,n_break_after) +
    div(n_validate_trials,n_break_after) - 1

  for trial in 1:n_trials
    if trial == 1
      marker = moment(record,"experiment_start")
    elseif trial % n_break_after == 1
      n = div(trial,n_break_after)
      addbreak(myinstruct("You can now take a break (break $n of $total_breaks)"))
      marker = moment(record,"block_start")
    else
      marker = moment()
    end

    addtrial(marker,real_trial(:medium,phase="test"))
  end

  message = moment(display,"""
  Almost done! Please contact the experimenter before you continue.
  """)
  addbreak(message,await_response(iskeydown(end_break_key)))

  addbreak(moment(display,joinpath("Images","navy_aba_04.png")),
    await_response(iskeydown(end_break_key)))

  addbreak(moment(display,"Wait for the experiment to press continue..."),
           await_response(iskeydown(end_break_key)))

  for trial in 1:n_validate_trials
    if trial > 1 && trial % n_break_after == 1
      n = div(trial,n_break_after) + div(n_trials,n_break_after)
      addbreak(myinstruct("You can now take a break (break $n of $total_breaks)"))
      marker = moment(record,"block_start")
    else
      marker = moment()
    end

    addtrial(marker,validate_trial(:medium,phase="validate"))
  end
end

run(experiment)
