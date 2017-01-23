Pkg.add("Weber",v"0.2.3")
open("calibrate.jl","w") do s
  println(s,"# call run_calibrate() to select an appropriate attenuation.")
  println(s,"const atten_dB = 30")
end
