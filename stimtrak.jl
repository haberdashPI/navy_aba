module WeberDAQmx
using Weber
using PyCall
import Weber: record

export daq_extension

type DAQmx <: Weber.Extension
  port::String
  codes::Dict{String,Int}
  reserved::Array{String}
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

daq_extension(::Void;codes=nothing) = EmptyDAQmx()
function daq_extension(port::String;codes=Dict{String,Int}())
  pyDAQmx = PyObject(nothing)
  np = PyObject(nothing)

  try
    pyDAQmx = pyimport("PyDAQmx","PyDAQmx","haberdashPI")
    np = pyimport("numpy")
  catch e
    if nidaq_missing(e)
      error("Could not find NI-DAQ library. Make sure it is installed.")
    else rethrow(e)
    end
  end

  try 
    task = pyDAQmx[:Task]()
    task[:CreateDOChan](port,"",pyDAQmx[:DAQmx_Val_ChanForAllLines])
    task[:StartTask]()
    atexit(() -> task[:StopTask]())

    bitarray = BitArray(8)
    pyarray = pycall(np[:zeros],PyArray,8,dtype="uint8")
    
    DAQmx(port,codes,keys(codes),bitarray,pyarray,0)
  catch e
    if isdaq_error(e)
	  error("NI-DAQ Serial port error: "*daq_message(e)*
		    "\n Python Stacktrace:\n"*string(e))
    else rethrow(e) end
  end
end
  
  
# any other codes are automatically selected by calling `DAQcode(code)`
function daq_code(daq::DAQmx,str::String)
  get!(daq.codes,str) do
    daq.N += 1
    while daq.N in daq.reserved
      daq.N += 1
    end

    if daq.N > 0xff
      error("The code \"$str\" is the 257th code, but only 256 are allowed.")
    end
    
    return UInt8(daq.N)
  end
end

# DAQwrite sends a code to the NI-DAQ interface

function daq_write(daq::DAQmx,str::String)
  try 
    daq.bitarray.chunks[1] = daq_code(daq,str)
    daq.pyarray[:] = bitarray
    daq.task[:WriteDigitalLines](1,1,10.0,pyDAQmx[:DAQmx_Val_GroupByChannel],
                                 daq.pyarray,nothing,nothing)
    reinterpret(Int,daq.bitarray.chunks[1])
  catch e
    if isdaq_error(e)
	  error("NI-DAQ Serial port error: "*daq_message(e)*
		    "\n Python Stacktrace:\n"*string(e))
    else rethrow(e) end
  end
end

function record(e::Weber.ExtendedExperiment{DAQmx},code;kwds...)
  record(e.next_extension,code;daq_code = daq_write(e.extension,code),kwds...)
end
end

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
