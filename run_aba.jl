#!/usr/bin/env julia

# TODO: make sure this shows the right number of breaks.
# TODO: one longer break in the middle

# different code for each of the three repetiats
# in the trial
# code for the very first

using Weber
using Weber.Cedrus
include("calibrate.jl")
include("stimtrak.jl")
setup_sound(buffer_size=buffer_size)

version = v"0.1.2"
sid,trial_skip =
  @read_args("Runs an intermittant aba experiment, version $version.")

const ms = 1/1000
const st = 1/12

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

n_repeat_example = 30

function aba(step)
  A = ramp(tone(A_freq,tone_len))
  B = ramp(tone(A_freq * 2^step,tone_len))
  gap = silence(tone_SOA-tone_len)
  attenuate([A;gap;B;gap;A],atten_dB)
end

medium = 6st
medium_str = "6st"
stimuli = Dict(:low => aba(3st),:medium => aba(medium),:high => aba(18st))

stream_1 = key":cedrus2:"
stream_2 = key":cedrus5:"

isresponse(e) = iskeydown(e,stream_1) || iskeydown(e,stream_2)

function create_aba(stimulus,index=0,isfirst=false;info...)
  prefix = isfirst? "first_" : ""
  
  [moment(play,stimuli[stimulus]),
   moment(record,prefix*"stimulus_$index",stimulus=stimulus;info...)]
end

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

  stim = [create_aba(stimulus;info...),moment(aba_SOA)]

  [resp,show_cross(),moment(repeated(stim,stimuli_per_response)),await]
end

function real_trial(stimulus,isfirst;limit=trial_spacing,info...)
  resp = response(stream_1 => "stream_1",
                  stream_2 => "stream_2";info...)
  
  stimuli = map(1:stimuli_per_response) do index
    [create_aba(stimulus,index,isfirst;info...),moment(aba_SOA)]
  end

  [resp,show_cross(),stimuli,moment(limit)]
end

function validate_trial(stimulus,isfirst;limit=trial_spacing,info...)
  resp = response(stream_1 => "switches_1_or_0",
                  stream_2 => "switches_2_or_more";info...)

  stimuli = map(1:stimuli_per_response) do index
    [create_aba(stimulus,index,isfirst;info...),moment(aba_SOA)]
  end

  [resp,show_cross(),stimuli,moment(limit)]
end


exp = Experiment(
  columns = [
    :sid => sid,
    :condition => "pilot",
    :version => version,
    :separation => medium_str,
    :stimulus,:phase,:stimtrak
  ],
  skip=trial_skip,
  extensions=[stimtrak(stimtrak_port),CedrusXID()],
  moment_resolution=moment_resolution,
)

function cedrus_instruct(str)
  text = visual(str*" (Hit \"M\" key to continue...)")
  m = moment() do
    record("instructions")
    display(text)
  end
  [m,await_response(iskeydown(key":cedrus3:"))]
end

setup(exp) do
  addbreak(moment(record,"start"))

  addbreak(
    cedrus_instruct("""

      In each trial of the present experiment you will hear a series of beeps.
      This may appear to proceeded in a galloping rhythm or it may sound like
      two distinct series of tones."""),

    cedrus_instruct("""

      For instance, the following example will normally seem to have
      a galloping-like rhythm."""))

  addpractice(show_cross(),
              repeated([create_aba(:low,phase="practice"),moment(aba_SOA)],
                       n_repeat_example))

  addbreak(cedrus_instruct("""

      On the other hand, normally the following example will not appear 
      to gallop."""))

  addpractice(show_cross(),
              repeated([create_aba(:high,phase="practice"),moment(aba_SOA)],
                       n_repeat_example))

  addbreak(
    cedrus_instruct("""

      In this experiment we'll be asking you to listen for whether it appears
      that the tones "gallop", or do not."""),

    cedrus_instruct("""

      Every once in a while, we want you to indicate what you heard most often,
      a gallop or something else. Let's practice a bit.  Use the orange button
      to indicate that you heard a "gallop" most of the time, and otherwise use
      the yellow button.
      
      """))

  addpractice(
    repeated(practice_trial(:medium,phase="practice",limit=10trial_spacing),
             num_practice_trials))

  addbreak(cedrus_instruct("""

    In the real experiment, your time to respond will be limited. Let's
    try another practice round, this time a little bit faster.
    """))

  addpractice(
    repeated(practice_trial(:medium,phase="practice",limit=2trial_spacing),
             num_practice_trials))

  addbreak(cedrus_instruct("""

    In the real expeirment, try to respond before the next trial begins, but
    even if you don't please still respond."""))

  anykey = moment(display,"Hit any key to start the real experiment...")
  addbreak(anykey,await_response(iskeydown))

  for trial in 1:n_trials
    addbreak_every(n_break_after,n_trials+n_break_after/2)
    addtrial(real_trial(:medium,phase="test",trial == 1))
  end

  message = moment(display,"""
  Almost done! Please contact the experimenter before you continue.
  """)
  addbreak(message,await_response(iskeydown(key"`")))

  addbreak(cedrus_instruct("""
    You may have noticed that, on occasion, within a single trial,
    the sound switches between gallping and not galloping multiple times.
  """),
  cedrus_instruct("""
    In the following trials hit orange if you hear one or no switches. Hit 
    the yellow if you hear more than one switch in a single trial.
    It is possible you will never hit one of the buttons.
  """))

  for trial in 1:n_validate_trials
    addbreak_every(n_break_after,n_validate_trials)
    addtrial(validate_trial(:medium,phase="validate",trial == 1))
  end
end

play(attenuate(ramp(tone(1000,1)),atten_dB))
run(exp)
