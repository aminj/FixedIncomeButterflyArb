function out=SwapRate(swap_rate_vect, maturities, swap_date_vect, thisdate, thismat)
    ind=find(swap_date_vect==thisdate,1);
    swap_rates=swap_rate_vect(ind,:);
    out=spline(maturities, swap_rates,thismat);
end
