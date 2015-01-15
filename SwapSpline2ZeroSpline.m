function zero = SwapSpline2ZeroSpline(SwapRate, T)
    finalMaturity = 10;

    df = zeros(finalMaturity*2,1);
    df(1) = 1/(1+SwapRate(.5)/200);
    
    mat = (1:finalMaturity*2)';
    for i = 2:finalMaturity*2
        c = SwapRate(i/2)/100;
        df(i) = (1-c/2*sum(df(1:i-1)))/(1+c/2);
    end
    zero = spline(mat/2, 100*(df.^(-1./(mat/2))-1), T);
end
