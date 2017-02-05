using SerialPorts

const stimtraks = (stimtrak_port != nothing ? SerialPort(stimtrak_port) : DevNull)
const stimcodes = Dict{String,UInt8}()
stimcode = begin
  let N = 0
    str -> get!(stimcodes,str) do
      if N <= 0xff
        N += 1
        UInt8(N-1)
      else
        error("The code \"$str\" is the 257th code, but only 256 are allowed.")
      end
    end
  end
end

function stimtrak(code;kwds...)
  x = stimcode(code)
  write(stimtraks,x)
  push!(kwds,:stimtrak => x)
end


