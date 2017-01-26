#!/usr/bin/env julia

using Weber
include("calibrate.jl")
setup_sound(buffer_size=buffer_size)

version = v"0.0.6"
sid,trial_skip =
  @read_args("Runs an intermittant aba experiment, version $version.")

const ms = 1/1000
const st = 1/12

# We might be able to change this to ISI now that there
# is no gap.
tone_len = 75ms
tone_SOA = 200ms
aba_SOA = 4tone_SOA
A_freq = 400
response_spacing = aba_SOA
n_trials = 1360
n_break_after = 85
stimuli_per_response = 2

n_repeat_example = 30
num_practice_trials = 20

function aba(step)
  A = ramp(tone(A_freq,tone_len))
  B = ramp(tone(A_freq * 2^step,tone_len))
  gap = silence(tone_SOA-tone_len)
  sound(attenuate([A;gap;B;gap;A],atten_dB))
end

medium_st = 6st
medium_str = "6st"
stimuli = Dict(:low => aba(3st),:medium => aba(medium_st),:high => aba(18st))
key_enter = Weber.KeyboardKey(13)
isresponse(e) = iskeydown(e,key"p") ||
                iskeydown(e,key"q") ||
                iskeydown(e,key_enter)

function create_aba(stimulus;info...)
  sound = stimuli[stimulus]
  moment() do t
    play(sound)
    record("stimulus",stimulus=stimulus;info...)
  end
end

# runs an entire trial
 function practice_trial(stimulus;limit=response_spacing,info...)
   resp = response(key"q" => "stream_1",
                   key"p" => "stream_2",
                   key_enter => "unsure";info...)

  go_faster = visual("Faster!",size=50,duration=500ms,y=0.15,priority=1)
  waitlen = aba_SOA*stimuli_per_response+limit
  min_wait = aba_SOA*stimuli_per_response+response_spacing
  await = timeout(isresponse,waitlen,atleast=min_wait) do time
    record("response_timeout";info...)
    display(go_faster)
  end

  stim = [create_aba(stimulus;info...),moment(aba_SOA)]

  [resp,show_cross(),moment(repeated(stim,stimuli_per_response)),await]
end

function real_trial(stimulus;limit=response_spacing,info...)
  resp = response(key"q" => "stream_1",
                  key"p" => "stream_2",
                  key_enter => "unsure";info...)
  stim = [create_aba(stimulus;info...),moment(aba_SOA)]

  [resp,show_cross(),moment(repeated(stim,stimuli_per_response)),
   moment(aba_SOA*stimuli_per_response + limit)]
end

exp = Experiment(sid = sid,condition = "pilot",version = version,
				         separation = medium_str,skip=trial_skip,
                 moment_resolution=moment_resolution,
                 columns = [:stimulus,:phase])

setup(exp) do
  start = moment(t -> record("start"))

  addbreak(
    instruct("""

      In each trial of the present experiment you will hear a series of beeps.
      This may appear to proceeded in a galloping rhythm or it may sound like
      two distinct series of tones."""),

    instruct("""

      For instance, the following example will normally seem to be
      galloping."""))

  addpractice(show_cross(),
              repeated([create_aba(:low,phase="practice"),moment(aba_SOA)],
                       n_repeat_example))

  addbreak(instruct("""

      On the other hand, normally the following example will eventually seem to
      be two separate series of tones."""))

  addpractice(show_cross(),
              repeated([create_aba(:high,phase="practice"),moment(aba_SOA)],
                       n_repeat_example))

  x = stimuli_per_response
  addbreak(
    instruct("""

      In this experiment we'll be asking you to listen for whether it appears
      that the tones "gallop", or are separate from one antoher."""),

    instruct("""

      Every once in a while, we want you to indicate what you heard most often,
      a gallop or separate tones. Let's practice a bit.  Use "Q" to indicate
      that you heard a "gallop" most of the time, and "P" otherwise.
      If you're unsure press "Enter"  Respond as promptly as you can."""))

  addpractice(
    repeated(practice_trial(:medium,phase="practice",limit=10response_spacing),
             num_practice_trials))

  addbreak(instruct("""

    In the real experiment, your time to respond will be limited. Let's
    try another practice round, this time a little bit faster.
  """) )

  addpractice(
    repeated(practice_trial(:medium,phase="practice",limit=2response_spacing),
             num_practice_trials))

  addbreak(instruct("""

    In the real experiment, your time to respond will be even more limited.  Try
    to respond before the next trial begins, but even if you don't please still
    respond."""))

  str = visual("Hit any key to start the real experiment...")
  anykey = moment(t -> display(str))
  addbreak(anykey,await_response(iskeydown))

  for trial in 1:n_trials
    addbreak_every(n_break_after,n_trials)
    addtrial(real_trial(:medium,phase="test"))
  end
end

play(attenuate(ramp(tone(1000,1)),atten_dB))
run(exp)
