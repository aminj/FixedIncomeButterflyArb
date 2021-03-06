% Implementation of Duarte et al (2006) YC arb strategy
% using closed-form formulas from Moreno (2003)

clear; close all;
[data, ~, draw] = xlsread('Swap Rates-BB.xlsx', 'Par Rates');

Mat_vect=[1 4 7 10 13];

dur_win=3:314;
whole_input_swap_rates=cell2mat(draw(dur_win,Mat_vect+1));

whole_input_swap_dates=[];
for i = dur_win
    whole_input_swap_dates(i-2)=datenum(cell2mat(draw(i,1)));
end

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



% next steps:
% - write the code for parameter estimation
% - set up trading strategies using deviations from above
% - function to compute hedge ratios
% - distribution of future moves to compute risk analytics (targets, stop-loss, half-lifes, etc.)
% - function implementing a yield curve to price our trades (eg. Nelson-Siegel)
% - compute returns (carry, rolldown, etc)
% - backtest all of this

% more next steps:
% - implement more models via DF functions
% - do some research on robust ways to estimate the parameters
% - extend to interest rate options
% - mess around with horizons (both trading and estimation)
% - mess around with data frequency (eg. weekly vs monthly data)
% - compute mkt price of risk, do something interesting with that involving 
%   P vs Q measures?