using WeberDAQmx

stop_record = 0xfd
start_record = 0xfc
manual_start_record = 0x29

stimtrak(port) = daq_extension(
  port,
  eeg_sample_rate = 512,
  codes = Dict(
    "trial_start" => start_record,
    "break_start" => stop_record,
    "paused" => stop_record,
    "unpaused" => start_record,
    "terminated" => stop_record,
    "UNUSED" => manual_start_record,
    "stream_1" => 1,
    "stream_2" => 2,
    "stream_1_up" => 3,
    "stream_2_up" => 4,
    "no_switches" => 5,
    "no_switches_up" => 6,
    "switches" => 7,
    "switches_up" => 8,
    "stimulus" => 9
  )
)
