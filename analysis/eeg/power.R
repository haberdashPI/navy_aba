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

## meta-analysis of ERP effect sizes
D = c()
# Bramon, E., Rabe-Hesketh, S., Sham, P., Murray, R. M., & Frangou,
# S. (2004). Meta-analysis of the P300 and P50 waveforms in
# schizophrenia. Schizophrenia research, 70(2), 315-329.
D[1] = 0.85

# Polich, J., Pollock, V. E., & Bloom, F. E. (1994). Meta-analysis of P300
# amplitude from males at risk for alcoholism. Psychological bulletin, 115(1),
# 55.
D[2] = 0.35

# Umbricht, D., & Krljes, S. (2005). Mismatch negativity in schizophrenia: a
# meta-analysis. Schizophrenia research, 76(1), 1-23.
D[3] = 0.99

# Polich, J. (1996). Meta‐analysis of P300 normative aging
# studies. Psychophysiology, 33(4), 334-353.
D[4] = 1.27

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

## based on lowest hypothetical effect size
retrodesign(0.1*min(D)*msd,sediff,df=13)
retrodesign(0.5*min(D)*msd,sediff,df=13)
retrodesign(min(D)*msd,sediff,df=13)
retrodesign(median(D)*msd,sediff,df=13)
retrodesign(max(D)*msd,sediff,df=13)

retrodesign(0.1*min(D)*msd,sediff,df=20)
retrodesign(0.5*min(D)*msd,sediff,df=20)
retrodesign(min(D)*msd,sediff,df=20)
retrodesign(median(D)*msd,sediff,df=20)
retrodesign(max(D)*msd,sediff,df=20)
