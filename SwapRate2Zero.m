function Bout=SwapRate2Zero(SwapRates, ZeroMaturity, swap_coupon_freq)
    %SwapRates should be in the form of @(mat) SwapRate(mat)
    %swap_coupon_freq is 1/4 for 4 coupon per year

    max_mat=ZeroMaturity(1)/12;
    swap_freq=swap_coupon_freq;
    T=swap_freq:swap_freq:max_mat+swap_freq;
    B=zeros(size(T));
    count=0;
    for i=T
        count=count+1;
        Ci=SwapRates(i)/400;
        BC=sum(B*Ci);
        B(count)=(1-BC)/(Ci+1);
    end
    Z=(1./B).^(1./(1:length(T)))-1;
    Bout=spline([0 T], [0 Z], fliplr(max_mat:-swap_freq:0));

end

        

    
    
