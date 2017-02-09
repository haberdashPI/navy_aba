
using PyCall

stop_code = 0xfd
start_code = 0xfc
manual_start_stop = 0x29

# define any codes you what set to a particular value here
const DAQcodes = Dict(
  "pause" => stop_code,
  "unpaused" => start_code,
  "terminated" => stop_code
)

# any other codes are automatically selected by calling `DAQcode(code)`
DAQcode = begin
  let N = -1, reserved = values(DAQcodes)
    str -> get!(DAQcodes,str) do
      N += 1
      while N in reserved
        N += 1
      end

      if N > 0xff
        error("The code \"$str\" is the 257th code, but only 256 are allowed.")
      end

      return UInt8(N)
    end
  end
end

# DAQwrite sends a code to the NI-DAQ interface
# (connected to biosemi to code stimtrak events)
const missing_library_error = "Location of niDAQmx library and include file unknown"
function nidaq_missing(e::PyCall.PyError)
  :message in keys(e.val) && startswith(String(e.val[:message]),missing_library_error)
end
nidaq_missing(e) = false

isdaq_error(e::PyCall.PyError) = e.T == pyDAQmx[:DAQmxFunctions][:DAQError]
isdaq_error(e) = false
daq_message(e::PyCall.PyError) = e.val[:mess]

DAQwrite = if stimtrak_port != nothing
  try
    global const pyDAQmx = pyimport_conda("PyDAQmx","PyDAQmx","haberdashPI")
    global const np = pyimport("numpy")
  catch e
    if nidaq_missing(e)
      error("Could not find NI-DAQ library. Make sure it is installed.")
    else rethrow(e)
    end
  end

  try 
    const DAQ_task = pyDAQmx[:Task]()
    DAQ_task[:CreateDOChan](stimtrak_port,"",pyDAQmx[:DAQmx_Val_ChanForAllLines])
    DAQ_task[:StartTask]()
    atexit(() -> DAQ_task[:StopTask]())

    const bitarray = BitArray(8)
    const pyarray = pycall(np[:zeros],PyArray,8,dtype="uint8")
    function fn(str)
      bitarray.chunks[1] = DAQcode(str)
      pyarray[:] = bitarray
      DAQ_task[:WriteDigitalLines](1,1,10.0,pyDAQmx[:DAQmx_Val_GroupByChannel],
                                   pyarray,nothing,nothing)
      reinterpret(Int,bitarray.chunks[1])
    end
  catch e
    if isdaq_error(e)
	error("NI-DAQ Serial port error: "*daq_message(e)*
		 "\n Python Stacktrace:\n"*string(e))
    else
	rethrow(e)
    end
  end
else
  code -> -1
end

function stimtrak(code;kwds...)
  push!(kwds,:stimtrak => DAQwrite(code))
end
