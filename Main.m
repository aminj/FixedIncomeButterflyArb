% Implementation of Duarte et al (2006) YC arb strategy
% using closed-form formulas from Moreno (2003)

clear; close all;
[data, ~, draw] = xlsread('Swap Rates-BB.xlsx', 'Par Rates');
%draw = csvread('Swap Rates-BB.csv');

Maturities=[2 3 5 7 10]

%this is a comment

Mat_vect=[1 4 7 10 13];

dur_win=3:314;
whole_input_swap_rates=cell2mat(draw(dur_win,Mat_vect+1));

whole_input_swap_dates=[];

for i = dur_win
    whole_input_swap_dates(i-2)=datenum(cell2mat(draw(i,1)));
end

ThisSwapRate=@(thisdate,thismat) SwapRate(whole_input_swap_rates, Maturities, whole_input_swap_dates, thisdate, thismat);

%plot([2:.1:9],ThisSwapRate(datenum(2004,12,31),[2:.1:9]))

last_day=datenum(2004,12,31); %Dec 2004

last_day_ind=find(whole_input_swap_dates<=last_day, 1, 'last' );

input_swap_dates=whole_input_swap_dates(1:last_day_ind);
input_swap_rates=whole_input_swap_rates(1:last_day_ind);
datestr(input_swap_dates(end))


model='DF_Vasicek2F'
init_params = [ 0.1; .1; .1 ; .1 ; .1 ; .1 ];
      

factors=factor_optimization(init_params, input_swap_rates, model);

options = optimset('Display', 'iter');
[param_vasi2, RMSE_vasi2] = fminsearch(@pricingErrors, init_params, options, factors, input_swap_rates, 1/5*ones(1,5), model);

factors=factor_optimization(param_vasi2, input_swap_rates, model);

V=PriceDiff(parameters,  factors, input_swap_rates, model)
