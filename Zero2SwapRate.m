function c = Zero2SwapRate(tau, DF)
c = 200*(1-DF(tau))./sum(DF(0.5:0.5:tau),2);