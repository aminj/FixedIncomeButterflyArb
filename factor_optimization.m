function out=factor_optimization(init_params, input_swap_rates, model)
    fhandle=str2func(model);
    n=size(input_swap_rates,1);
    SwapRateMdl = @(fac, T) Zero2SwapRate(T, @(tau) fhandle(init_params, fac, tau));
    time_vector=[2 3 5 7 10];
    for i=1:n   
        factors(:, i) = fsolve(@(fac) [SwapRateMdl(fac, time_vector(1)) - input_swap_rates(i,1) ; SwapRateMdl(fac, time_vector(5)) - input_swap_rates(i,5)], [0;0], optimoptions('fsolve','Display','off'));
    end

    out=factors;
end