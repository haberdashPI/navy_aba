Pkg.add("Weber",v"0.3.2")
Pkg.add("SerialPorts")
open("calibrate.jl","w") do s
  print(s,"""
  # call run_calibrate() to select an appropriate attenuation.
  const atten_dB = 30
  
  # call Pkg.test(\"Weber\"). If the timing test fails, increase 
  # moment resolution to avoid warnings.
  const moment_resolution = Weber.default_moment_resolution
  
  # increase buffer size if you are hearing audible glitches in the sound.
  const buffer_size = 256

  # select an appropriate serial port for stimtrak using
  # SerailPorts.list_serialports() (after calling using SerialPorts)
  const stimtrak_port = nothing
  """)
end
