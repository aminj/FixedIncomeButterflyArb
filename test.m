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
MyPort.append_swaps(this_day, datenum(2005,12,31), 1000);
MyPort.append_swaps(this_day, datenum(2006,12,31), -2000);
MyPort.append_swaps(this_day, datenum(2013,12,31), 1000);

MyPort.evaluate(ThisSwapRate, this_day+90, false)