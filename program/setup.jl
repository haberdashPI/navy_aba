Pkg.add("Weber")
Pkg.and("WeberDAQmx")
Pkg.add("WeberCedrus")
Pkg.add("Lazy")

if !isfile("calibrate.jl")
  open("calibrate.jl","w") do s
    print(s,"""
    # call run_calibrate() to select an appropriate attenuation.
    const atten_dB = 30

    # call Pkg.test(\"Weber\"). If the timing test fails, increase
    # moment resolution to avoid warnings.
    const moment_resolution = Weber.default_moment_resolution

    const stream_1 = key"q"
    const stream_2 = key"p"
    const end_break_key = key"`"
    const oddball_key = key"q"

    # select an appropriate serial port for stimtrak using
    # SerailPorts.list_serialports() (after calling `using SerialPorts`)
    const stimtrak_port = nothing
    """)

  end
end
