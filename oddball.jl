
function oddball_paradigm(fn,n_oddballs,n_standards;lead=20)
  oddballs_left = n_oddballs
  standards_left = n_standards
  oddball_n_stimuli = n_oddballs + n_standards
  last_stim_odd = false
  for trial in 1:oddball_n_stimuli
    stimuli_left = oddballs_left + standards_left
    oddball_chance = oddballs_left / (stimuli_left - n_oddballs)

    if trial > lead && !last_stim_odd && rand() < oddball_chance
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
