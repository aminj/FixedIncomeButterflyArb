function c = ZeroToSwapRate(tau, DF)
c = 200*(1-DF(tau))./sum(DF(0.5:0.5:tau),2);