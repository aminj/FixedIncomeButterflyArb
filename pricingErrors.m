function l2e=pricingErrors(parameters,  factors, input_swap_rates, input_weights, model)

    fhandle=str2func(model);
    %param2=num2cell(parameters);
    f_tau=@(tau)fhandle(parameters,factors, tau);
    l2e=0;
    SwapRateMdl = @(T) Zero2SwapRate(T, f_tau);
    
    time_vector=[2 3 5 7 10];
    for i= 1:5
       l2e=l2e+input_weights(i)*sum((SwapRateMdl( time_vector(i))' - input_swap_rates(:,i)).^2);
    end
    l2e=sqrt(l2e/size(input_swap_rates,1));
end
