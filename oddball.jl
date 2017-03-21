"""
    oddball_paradigm(trial_body_fn,n_oddballs,n_standards;
                     lead=20,no_oddball_repeats=true)

Helper to generate trials for an oddball paradigm.

The trial_body_fn should setup stimulus presentation: it takes one argument,
indicating if the stimulus should be a standard (false) or oddball (true)
stimulus.

It is usually best to use oddball_paradigm with a do block syntax, as follows.

    oddball_paradigm(20,150) do isoddball
      if isoddball
        addtrial(...create oddball trial here...)
      else
        addtrial(...create standard trial here...)
      end
    end

# Keyword arguments

* **lead**: determines the number of standards that repeat before any oddballs
  get presented
* **no_oddball_repeats**: determines if at least one standard must occur
  between each oddball (true) or not (false).
"""
function oddball_paradigm(fn,n_oddballs,n_standards;lead=20,no_oddball_repeats=true)
  oddballs_left = n_oddballs
  standards_left = n_standards
  oddball_n_stimuli = n_oddballs + n_standards
  last_stim_odd = false
  for trial in 1:oddball_n_stimuli
    stimuli_left = oddballs_left + standards_left
    oddball_chance = oddballs_left / (stimuli_left - n_oddballs)

    if (trial > lead &&
        (!last_stim_odd || no_oddball_repeats) &&
        rand() < oddball_chance)

      last_stim_odd = true
      oddballs_left -= 1
      fn(true)
    else
      last_stim_odd = false
      standards_left -= 1
      fn(false)
    end
  end
end
