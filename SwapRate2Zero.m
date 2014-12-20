function B=SwapRate2Zero(SwapRates, ZeroMaturity)
    %SwapRates should be in the form of @(mat) SwapRate(mat)
    
    %if (ZeroMaturity(3)==0) && (mod(ZeroMaturity(2),3)==0)
    if (mod(ZeroMaturity(1),3)==0)
        max_mat=ZeroMaturity(1)/12;
        swap_freq=.25;
        T=swap_freq:swap_freq:max_mat;
        B=zeros(size(T));
        count=0;
        for i=T
            count=count+1;
            Ci=SwapRates(i)/400;
            BC=sum(B*Ci);
            B(count)=(1-BC)/(Ci+1);
        end
    end
end

        

    
    
