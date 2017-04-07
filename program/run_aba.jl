#!/usr/bin/env julia

# TODO: make sure this shows the right number of breaks.
# TODO: one longer break in the middle

# different code for each of the three repetiats
# in the trial
# code for the very first

using Weber
using WeberCedrus
using Lazy
include("calibrate.jl")
include("stimtrak.jl")

version = v"0.2.2"
sid,trial_skip =
  @read_args("Runs an intermittant aba ``experiment, version $version.")

################################################################################
# settings

const ms = 1/1000
const st = 1/12

low = 3st
medium = 6st
high = 18st
medium_str = "6st"

tone_len = 73ms
tone_SOA = 175ms
aba_SOA = 4tone_SOA
A_freq = 400

stimuli_per_response = 3
trial_spacing = aba_SOA

n_trials = 600
num_practice_trials = 12
n_break_after = 75
n_validate_trials = 2n_break_after

n_repeat_example = 20


################################################################################
# expeirment and trial definitions

experiment = Experiment(
  columns = [
    :sid => sid,
    :condition => "pilot",
    :version => version,
    :separation => medium_str,
    :stimulus,:phase,:stimtrak
  ],
  data_dir=joinpath("..","data","csv"),
  skip=trial_skip,
  extensions=[stimtrak(stimtrak_port),Cedrus()],
  moment_resolution=moment_resolution,
)

function aba(step,repeat=stimuli_per_response)
  A = ramp(tone(A_freq,tone_len))
  B = ramp(tone(A_freq * 2^step,tone_len))
  gap = silence(tone_SOA-tone_len)
  aba = attenuate([A;gap;B;gap;A],atten_dB)
  aba_ = [aba;silence(aba_SOA-duration(aba))]
  reduce(vcat,repeated(aba_,repeat))
end

stimuli = Dict(:medium => aba(medium))

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
  addbreak(moment(250ms,play,@> tone(1000,1) ramp attenuate(atten_dB)))

  instruction_image1 = load(joinpath("Images","navy_aba_01.png"))
  instruction_image2 = load(joinpath("Images","navy_aba_02.png"))
  instruction_image3 = load(joinpath("Images","navy_aba_03.png"))

  example1 = aba(low,n_repeat_example)
  addbreak(
    moment(display,instruction_image1),
    await_response(iskeydown(end_break_key)),
    show_cross(),moment(250ms,play,example1),moment(duration(example1)),
    moment(display,instruction_image1),
    await_response(iskeydown(end_break_key)),
    moment(display,instruction_image2),
    await_response(iskeydown(end_break_key)))

  example2 = aba(high,n_repeat_example)
  addbreak(
    moment(display,instruction_image3),
    await_response(iskeydown(end_break_key)),
    show_cross(),moment(play,example2),moment(duration(example2)))

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
    repeated(practice_trial(:medium,phase="practice",limit=10trial_spacing),
             num_practice_trials))

  addbreak(myinstruct("""

    In the real experiment, your time to respond will be limited. Let's
    try another practice round, this time a little bit faster.
    """))

  addpractice(
    repeated(practice_trial(:medium,phase="practice",limit=2trial_spacing),
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

  instruction_image4 = load(joinpath("Images","navy_aba_04.png"))
  addbreak(moment(display,instruction_image4),
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
