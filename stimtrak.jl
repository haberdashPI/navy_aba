
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
DAQwrite = if stimtrak_port != nothing
  try
    const pyDAQmx = pyimport_conda("PyDAQmx","PyDAQmx","haberdashPI")
  catch e

    if isa(e,PyCall.PyError) && startswith(String(e.val["message"]),missing_library_error)
      error("Could not find NI-DAQ library. Make sure it is installed.")
    else rethrow(e)
    end
  end
  const DAQ_task = pyDAQmx[:Task]()
  DAQ_task[:StartTask]()
  DAQ_task[:CreateDOChan](stimtrak_port,"",pyDAQmx[:DAQmx_Val_ChanForAllLines])
  atexit(() -> DAQ_task[:StopTask]())

  const bitarray = BitArray(8)

  function fn(str)
    code = DAQcode(str)
    bitarray.chunks = [code]
    DAQ_task[:WriteDigitalLines](1,1,10.0,pyDAQmx[:DAQmx_Val_GroupByChannel],
                                 convert(Array{Bool},bitarray),
                                 nothing,nothing)
    Int(code)
  end
else
  code -> -1
end

function stimtrak(code;kwds...)
  push!(kwds,:stimtrak => DAQwrite(code))
end
