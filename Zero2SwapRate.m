function c=Zer2SwapRate(T,DF)
    SumDF=DF(1/2);
    for i =2:T*2
        SumDF=SumDF + DF(i/2);
    end
    c=(1-DF(T))./SumDF*2*100;
end
