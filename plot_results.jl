using DataFrames
using Lazy
using Gadfly
using DataFramesMeta
using Colors
# using Query

# file_pat = r"[0-9]+_pilot_0.0.5_8st_2017.*\.csv"
# results = @>> readdir("data") begin
#   filter(x -> ismatch(file_pat,x))
#   map(x -> joinpath("data",x))
#   map(readtable)
#   reduce(vcat)
# end

# rts = @from row in results begin
#   @where row.trial >= 1
#   @group row by (row.sid,row.trial) into trial
#   @select {
#     trial_length = last(trial).time - first(trial).time
#   }
#   @collect DataFrame
# end

rts = readtable("rts2.csv")
rts = @where(rts,(:code .== "stream_1") | (:code .== "stream_2"))

function response_to_float(rs)
  result = zeros(length(rs))
  for i in eachindex(result)
    result[i] = (isna(rs[i]) ? NaN : rs[i] == "stream_2")
  end
  result
end

function filternums(x,τ)
  y = zeros(x)
  α = 1/τ
  y[1] = (isnan(x[1]) ? 0.0 : x[1])
  for i in 2:length(x)
    if isnan(x[i])
      y[i] = y[i-1]
    else
      y[i] = α*x[i] + (1-α)*y[i-1]
    end
  end
  y
end

# streak_data = @by(rts,[:sid,:version],streaks = streaks(response_to_float(:response)))
# hist = plot(streak_data,x=:streaks,ygroup=:version,
#             Guide.xlabel("Percept length (in trials)"),
#             Geom.subplot_grid(free_y_axis=true,
#                               Geom.histogram(bincount=maximum(streak_data[:streaks]))))
# draw(PDF("plots/percet_length_hist.pdf",8inch,4inch),hist)

# look at averages across blocks
# check histogram bins (one number per bin)
# check weird response times
# reinforce the break lenght
# look at the presnizter paper, to give a break

df = @by(rts,:sid,DataFrame(wresp=filternums(response_to_float(:code),3),
                            time=:time))
df[:tau] = "3"
dfc = @by(rts,:sid,DataFrame(wresp=filternums(response_to_float(:code),10),
                             time=:time))
dfc[:tau] = "10"
df = vcat(df,dfc)

dfc = @by(rts,:sid,DataFrame(wresp=filternums(response_to_float(:code),50),
                             time=:time))
dfc[:tau] = "50"
df = vcat(df,dfc)

dfc = @by(rts,:sid,DataFrame(wresp=filternums(response_to_float(:code),200),
                             time=:time))
dfc[:tau] = "200"
df = vcat(df,dfc)
 
plot(df,xgroup=:sid,x=:time,y=:wresp,color=:tau,Geom.subplot_grid(Geom.line))

draw(PDF("plots/mean_responses_scales.pdf",8inch,2.5inch),hstack(sidp...))
