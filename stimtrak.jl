include("daqmx.jl")
using WeberDAQmx

stop_record = 0xfd
start_record = 0xfc
manual_start_record = 0x29

stimtrak(port) = daq_extension(
  port,
  eeg_sample_rate = 512,
  codes = Dict(
    "trial_start" => start_record,
    "practice_start" => start_record,
    "break_start" => stop_record,
    "paused" => stop_record,
    "unpaused" => start_record,
    "terminated" => stop_record,
    "UNUSED" => manual_start_record
  )
)
