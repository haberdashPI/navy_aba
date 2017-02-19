include("daqmx.jl")
using WeberDAQmx

stop_record = 0xfd
start_record = 0xfc
manual_start_record = 0x29

manual_codes = Dict(
  "trial_start" => start_record,
  "break_start" => stop_record,
  "paused" => stop_record,
  "unpaused" => start_record,
  "terminated" => stop_record,
  "UNUSED" => manual_start_record
)

code_names = ["stream_1","stream_2","stream_1_up","stream_2_up",
               "switches_1_or_0","switches_2_or_more",
               "stimulus_1","stimulus_2","stimulus_3"]

codes = Dict(code => i for (i,code) in enumerate(code_names))
merge!(codes,manual_codes)

stimtrak(port) = daq_extension(port,eeg_sample_rate = 512,codes = codes)
