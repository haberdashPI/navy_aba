library(pwr)

# taken from davidson & pitts (2014) (2-factor 1-way ANOVA)
F = 15.2
t = sqrt(F) # T statistic for this difference
d = t / sqrt(21) # cohen's d
mdiff = 0.8
sediff = -mdiff/qt(0.001,20)

pwr.t.test(d=d,power=0.8,type="paired")

F = 6.2
t = sqrt(F) # T statistic for this difference
d = t / sqrt(21) # cohen's d
mdiff = 0.8
sediff = -mdiff/qt(0.02,20)

pwr.t.test(d=d,power=0.8,type="paired")

msd = sediff * sqrt(21)

## TODO:

## 1. collect effect sizes for various meta-analyses (not as relevant but
## based on more data) plus any effects from more directly relevant studies.

## 2. determine some inflation estimate for the effects of directly relevant
## studies (e.g. based on that recent Science article examining replications
## across psychology). Adjust the directly releveant study effects based on this
## estimate.

## 3. Use the resulting effect sizes to select a range of plausible effect
## sizes for the current study.

# WIP: effect sizes (Cohen's D) collected so far:

D = c()

###### P300
# Bramon, E., Rabe-Hesketh, S., Sham, P., Murray, R. M., & Frangou,
# S. (2004). Meta-analysis of the P300 and P50 waveforms in
# schizophrenia. Schizophrenia research, 70(2), 315-329.
D[1] = 0.85

# Polich, J., Pollock, V. E., & Bloom, F. E. (1994). Meta-analysis of P300
# amplitude from males at risk for alcoholism. Psychological bulletin, 115(1),
# 55.
D[2] = 0.35

# Polich, J. (1996). Meta‐analysis of P300 normative aging
# studies. Psychophysiology, 33(4), 334-353.
D[4] = 1.27

######## MMN

# Umbricht, D., & Krljes, S. (2005). Mismatch negativity in schizophrenia: a
# meta-analysis. Schizophrenia research, 76(1), 1-23.
D[3] = 0.99

####### Intermittant studies of Bi-stability

# TODO:

####### Streaming

# TODO:

## the following function is from:

# Gelman, A., & Carlin, J. (2014). Beyond Power Calculations Assessing Type S
# (Sign) and Type M (Magnitude) Errors. Perspectives on Psychological Science,
# 9(6), 641–651. https://doi.org/10.1177/1745691614551642

retrodesign <- function(A, s, alpha=.05, df=Inf, n.sims=10000){
  z <- qt(1-alpha/2, df)
  p.hi <- 1 - pt(z-A/s, df)
  p.lo <- pt(-z-A/s, df)
  power <- p.hi + p.lo
  typeS <- p.lo/power
  estimate <- A + s*rt(n.sims,df)
  significant <- abs(estimate) > s*z
  exaggeration <- mean(abs(estimate)[significant])/A
  return(list(power=power, typeS=typeS, exaggeration=exaggeration))
}

## TODO: calculate type S errors and exaggeration ratio with lowest, median and
## highest plausible effect size, for a variety of N
retrodesign(min(D)*msd,sediff,df=13)
retrodesign(median(D)*msd,sediff,df=13)
retrodesign(max(D)*msd,sediff,df=13)

retrodesign(min(D)*msd,sediff,df=20)
retrodesign(median(D)*msd,sediff,df=20)
retrodesign(max(D)*msd,sediff,df=20)
