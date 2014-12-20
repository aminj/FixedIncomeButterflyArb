clear; close all;clc;
[data, ~, draw] = xlsread('Swap Rates-BB.xlsx', 'Par Rates');
%draw = csvread('Swap Rates-BB.csv');

Maturities=[2 3 5 7 10];

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


this_day=datenum(2004,12,31); %Dec 2004
MyPort=portfolio(this_day);

swap1_enter_day=this_day;
swap1_maturity_day=datenum(2005,12,31);
swap1_position=1000;
MyPort.append_swaps(swap1_enter_day, swap1_maturity_day, swap1_position);

swap2_enter_day=this_day;
swap2_maturity_day=datenum(2006,12,31);
swap2_position=-2000;
MyPort.append_swaps(swap2_enter_day, swap2_maturity_day, swap2_position);

swap3_enter_day=this_day;
swap3_maturity_day=datenum(2013,12,31);
swap3_position=1000;
MyPort.append_swaps(swap3_enter_day, swap3_maturity_day, swap3_position);

CloseContracts=false;
EvaluatePortfolioAtDate=addtodate(datenum(2004,12,31), 3 , 'month');
MyPort.evaluate(ThisSwapRate, EvaluatePortfolioAtDate, CloseContracts)