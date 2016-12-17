#!/usr/bin/env julia

using Psychotask
using Lazy: @>

sid,trial_skip = @read_args("Runs an intermittent aba experiment")

const ms = 1/1000
const st = 1/12
atten_dB = 20

# We might be able to change this to ISI now that there
# is no gap.
tone_len = 50ms
tone_SOA = 120ms
aba_SOA = 4tone_SOA
A_freq = 300
response_timeout = 750ms
n_repeat_example = 20
n_trials = 140
n_break_after = 15
stimuli_per_response = 3
responses_per_phase = 7

response_pause = aba_SOA - 3tone_SOA

function aba(step)
  A = ramp(tone(A_freq,tone_len))
  B = ramp(tone(A_freq * 2^step,tone_len))
  gap = silence(tone_SOA-tone_len)
  [A;gap;B;gap;A]
end

stimuli = Dict(:low => aba(3st),:medium => aba(6st),:high => aba(12st))

# randomize presentations, but gaurantee that all stimuli are presented in equal
# quantity within the first and second half of trials
contexts = @> keys(stimuli) begin
  cycle
  take(n_trials)
  collect
  shuffle
end
 
isresponse(e) = iskeydown(e,key"p") || iskeydown(e,key"q")

function create_aba(stimulus;info...)
  sound = stimuli[stimulus]
  moment(aba_SOA) do t
    play(sound)
    record("stimulus",time=t,stimulus=stimulus;info...)    
  end
end

# runs an entire trial
function create_trial(stimulus;limit=response_timeout,info...)
  go_faster = render("Faster!",size=50,duration=500ms,y=0.15,priority=1)
  await = timeout(isresponse,limit) do time
    record("response_timeout",time=time;info...)
    display(go_faster)
  end

  resp = response(key"q" => "stream_1",key"p" => "stream_2";info...)

  x = [resp,show_cross(response_pause),
       repeated(create_aba(stimulus;info...),stimuli_per_response),await]
  repeat(x,outer=responses_per_phase)
end

function setup()
  start = moment(t -> record("start",time=t))

  clear = render(colorant"gray")
  blank = moment(t -> display(clear))

  addbreak(
    instruct("""

      In each trial of the present experiment you will hear a series of beeps.
      This may appear to proceeded in a galloping rhythm or it may sound like
      two distinct series of tones."""),

    instruct("""

      For instance, the following example will normally seem to be
      galloping."""))

  addpractice(blank,show_cross(response_pause),
              repeated(create_aba(:low,phase="practice"),n_repeat_example),
              moment(aba_SOA))

  addbreak(instruct("""

      On the other hand, normally the following example will eventually seem to
      be two separate series of tones."""))
  
  addpractice(blank,show_cross(response_pause),
              repeated(create_aba(:high,phase="practice"),n_repeat_example),
              moment(aba_SOA))

  x = stimuli_per_response
  addbreak(
    instruct("""

      In this experiment we'll be asking you to listen for whether it appears
      that the tones "gallop", or are separate from one antoher."""),

    instruct("""

      After every $x sounds, we want you to indicate what you heard most often,
      a gallop or separate tones. Let's practice a bit.  Use "Q" to indicate
      that you heard a "gallop" most of the time, and "P" otherwise.  Respond as
      promptly as you can.""") )

  addpractice(create_trial(:medium,phase="practice",limit=10response_timeout))

  addbreak(instruct("""
  
    In the real experiment, your time to respond will be limited. Let's
    try another practice round, this time a little bit faster.
  """) )

  addpractice(create_trial(:medium,phase="practice",limit=2response_timeout))
  
  addbreak(instruct("""

    In the real experiment, your time to respond will be even more limited. 
    Please try to respond before you see the "Faster!" flash, but even if
    it does flash, please still respond.
  """) )

  str = render("Hit any key to start the real experiment...")
  anykey = moment(t -> display(str))
  addbreak(anykey,await_response(iskeydown))
  
  for trial in 1:n_trials
    addbreak_every(n_break_after,n_trials)

    context_phase = create_trial(contexts[trial],phase="context")
    test_phase = create_trial(:medium,phase="test")
    addtrial(context_phase,test_phase)
  end
end

exp = Experiment(setup,condition = "pilot",sid = sid,version = v"0.0.1",
                 skip=trial_skip,columns = [:time,:stimulus,:phase])
play(attenuate(ramp(tone(1000,1)),atten_dB))
run(exp)
