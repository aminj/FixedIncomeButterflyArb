function out=PriceDiff(parameters,  factors, input_swap_rates, model)

    fhandle=str2func(model);
    %param2=num2cell(parameters);
    f_tau=@(tau)fhandle(parameters,factors, tau);
    l2e=0;
    SwapRateMdl = @(T) Zero2SwapRate(T, f_tau);
    
    time_vector=[2 3 5 7 10];
    for i= 1:5
        SwapMod=SwapRateMdl( time_vector(i))';
       out(i)= SwapMod(end)- input_swap_rates(end,i);
    end
end