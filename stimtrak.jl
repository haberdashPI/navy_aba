include("daqmx.jl")
using WeberDAQmx

stop_code = 0xfd
start_code = 0xfc
manual_start_stop = 0x29

stimtrak(port) = daq_extension(
  port,
  codes = Dict(
    "pause" => stop_code,
    "unpaused" => start_code,
    "terminated" => stop_code,
    "UNUSED" => manual_start_stop
  )
)
