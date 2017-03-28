module WeberDAQmx
using Weber
using PyCall
import Weber: record, setup

export daq_extension

type DAQmx <: Weber.Extension
  port::String
  codes::Dict{String,Int}
  reserved::Array{Int}
  wait_len::Float64
  N::Int
  bitarray::BitArray
  pyarray::PyArray
  task::PyObject
end

type EmptyDAQmx <: Weber.Extension
end

const missing_library_error = "Location of niDAQmx library and include file unknown"
function nidaq_missing(e::PyCall.PyError)
  :message in keys(e.val) && startswith(String(e.val[:message]),missing_library_error)
end
nidaq_missing(e) = false

isdaq_error(e::PyCall.PyError) = e.T == pyDAQmx[:DAQmxFunctions][:DAQError]
isdaq_error(e) = false
daq_message(e::PyCall.PyError) = e.val[:mess]

"""
    daq_extension(port;eeg_sample_rate,[codes])

Create a Weber extension that writes `record` events to a digital 
out line via the DAQmx API. This can be used to send trigger 
codes during eeg recording.

# Arguments

* port: should be `nothing`, to disable the extension, or 
  the port name for the digital output line.
* eeg_sample_rate: should be set to the sampling rate for
  eeg recording. This calibrates the code length for triggers.
* codes: a Dict that maps record event codes (a string) to a number.
  This should be an Integer less than 256. Any codes not
  specified here will be automatically set, based on the order
  in which codes are recieved.
"""
daq_extension(::Void;codes=nothing,eeg_sample_rate=nothing) = EmptyDAQmx()
function daq_extension(port::String;codes=Dict{String,Int}(),
                       eeg_sample_rate=nothing)
  # code clearing waits just a little longer than one eeg sample
  wait_len = 1.25/eeg_sample_rate

  # load pyDAQmx library
  try
    global const pyDAQmx = pyimport_conda("PyDAQmx","PyDAQmx","haberdashPI")
    global const group_by_channel = pyDAQmx[:DAQmx_Val_GroupByChannel]
    global const np = pyimport("numpy")
  catch e
    if nidaq_missing(e)
      error("Could not find NI-DAQ library. Make sure it is installed.")
    else rethrow(e)
    end
  end

  # setup the task
  task = PyObject(nothing)
  try
    task = pyDAQmx[:Task]()
    task[:CreateDOChan](port,"",pyDAQmx[:DAQmx_Val_ChanForAllLines])
    task[:StartTask]()
    atexit(() -> task[:StopTask]())
  catch e
    if isdaq_error(e)
	  error("NI-DAQ Serial port error: "*daq_message(e)*
		    "\n Python Stacktrace:\n"*string(e))
    else rethrow(e) end
  end

  bitarray = BitArray(8)
  pyarray = pycall(np[:zeros],PyArray,8,dtype="uint8")
  reserved = values(codes) |> collect
  push!(reserved,0x00) # 0 is used to clear the line
  DAQmx(port,codes,reserved,wait_len,0,bitarray,pyarray,task)
end


# any other codes are automatically selected by calling `DAQcode(code)`
function daq_code(daq::DAQmx,str::String)
  get!(daq.codes,str) do
    daq.N += 1
    while daq.N in daq.reserved
      daq.N += 1
    end

    if daq.N > 0xff
      error("The code \"$str\" is the 256th code, but only 255 are allowed.")
    end

    return UInt8(daq.N)
  end
end

# DAQwrite sends a code to the NI-DAQ interface

function daq_write(daq::DAQmx,str::String)
  try
    daq.bitarray.chunks[1] = daq_code(daq,str)
    daq.pyarray[:] = daq.bitarray
    daq.task[:WriteDigitalLines](1,1,10.0,group_by_channel,
                                 daq.pyarray,nothing,nothing)
    daq.pyarray[:] = 0
    sleep(daq.wait_len)
    daq.task[:WriteDigitalLines](1,1,10.0,group_by_channel,
                                 daq.pyarray,nothing,nothing)
    sleep(daq.wait_len)
    reinterpret(Int,daq.bitarray.chunks[1])
  catch e
    if isdaq_error(e)
	  error("NI-DAQ Serial port error: "*daq_message(e)*
		    "\n Python Stacktrace:\n"*string(e))
    else rethrow(e) end
  end
end

function setup(fn::Function,e::Weber.ExtendedExperiment{DAQmx})
  setup(next(e)) do
    addcolumn(:daq_code)
    fn()
  end
end

function record(e::ExtendedExperiment{DAQmx},code;kwds...)
  record(next(e),code;daq_code = daq_write(extension(e),code),kwds...)
end

end
