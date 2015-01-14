clear; close all;

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

% last_day=datenum(201,12,31); %Dec 2012
% 
% last_day_ind=find(whole_input_swap_dates<=last_day, 1, 'last' );

input_swap_dates=whole_input_swap_dates;
input_swap_rates=whole_input_swap_rates;





CALIBRATE = 1;  % set to 1 to run optimization

SR_all = whole_input_swap_rates;
mat = [2,3,5,7,10]; D = numel(mat);

window_calibration = 158:278; % Dec 2002 - Dec 2011
SR_calibration = SR_all(window_calibration,:);

params_init = [ 0.1676
                0.0148
                0.0077
                0.0140
                0.0133
                0.0058 ];

% calibration using global optimization & Kalman filter
if CALIBRATE
    problem = createOptimProblem('fmincon','objective', ...
                @(params) Kalman(params, SR_calibration), ...
                'x0',params_init, ...
                'lb',[-1;-1;0;-1;-1;0], ...
                'ub',[.5;.5;.5;.5;.5;.5], ...
                'options',optimset('Display', 'iter'));
    gs = GlobalSearch;
    [params_opt,~] = run(gs,problem);
else
    params_opt = params_init;
end

% get factors from calibrated model
[~, factors_calibration, P_XX_last] = Kalman(params_opt, SR_calibration);

% start trading out of sample
begin_trading = 279;
SR_trading = SR_all(begin_trading:end,:); % Jan 2012+ 
[~, factors_trading] = Kalman(params_opt, SR_trading, factors_calibration(:,end), P_XX_last);
M = Vasicek2F(params_opt);
SR = @(fac, T) Zero2SwapRate(T, @(tau) M.P(fac, tau));
SR_model_trading = [SR(factors_trading, 2) ...
           SR(factors_trading, 3) ...
           SR(factors_trading, 5) ...
           SR(factors_trading, 7) ...
           SR(factors_trading, 10)];
SR_model_trading = SR_model_trading(1:end-1,:);
n = size(SR_model_trading,1);

% plot out-of-sample deviations: actual vs model
figure;
subplot(2,1,1); plot((1:n)', 100*(SR_trading(:,1)-SR_model_trading(:,1)), 'r-'); title('2Y: Act-Mdl (bps)');
subplot(2,1,2); plot((1:n)', 100*(SR_trading(:,5)-SR_model_trading(:,5)), 'r-'); title('10Y: Act-Mdl (bps)');

figure;
subplot(3,1,1); plot((1:n)', 100*(SR_trading(:,2)-SR_model_trading(:,2)), 'r-'); title('3Y: Act-Mdl (bps)');
subplot(3,1,2); plot((1:n)', 100*(SR_trading(:,3)-SR_model_trading(:,3)), 'r-'); title('5Y: Act-Mdl (bps)');
subplot(3,1,3); plot((1:n)', 100*(SR_trading(:,4)-SR_model_trading(:,4)), 'r-'); title('7Y: Act-Mdl (bps)');

SR_model_calibration = [SR(factors_calibration, 2) ...
           SR(factors_calibration, 3) ...
           SR(factors_calibration, 5) ...
           SR(factors_calibration, 7) ...
           SR(factors_calibration, 10)];
SR_model_calibration = SR_model_calibration(1:end-1,:);
n = size(SR_model_calibration,1);

% plot out-of-sample deviations: actual vs model
figure;
subplot(2,1,1); plot((1:n)', 100*(SR_calibration(:,1)-SR_model_calibration(:,1)), 'r-'); title('2Y: Act-Mdl (bps)');
subplot(2,1,2); plot((1:n)', 100*(SR_calibration(:,5)-SR_model_calibration(:,5)), 'r-'); title('10Y: Act-Mdl (bps)');

figure;
subplot(3,1,1); plot((1:n)', 100*(SR_calibration(:,2)-SR_model_calibration(:,2)), 'r-'); title('3Y: Act-Mdl (bps)');
subplot(3,1,2); plot((1:n)', 100*(SR_calibration(:,3)-SR_model_calibration(:,3)), 'r-'); title('5Y: Act-Mdl (bps)');
subplot(3,1,3); plot((1:n)', 100*(SR_calibration(:,4)-SR_model_calibration(:,4)), 'r-'); title('7Y: Act-Mdl (bps)');

portfolio_vector=[];
PL_vect=[];
for t=1:3:n
    fac = factors_trading(:,t);
    thresh_open = 0.1; % trading thresholds
    thresh_close = 0.02;
    PL=0
    for i=1:length(portfolio_vector)
        EvaluatePortfolioAtDate=input_swap_dates(begin_trading+t-1);
        PL=PL+portfolio_vector(i).evaluate(ThisSwapRate, EvaluatePortfolioAtDate, false);
    end
    PL_vect=[PL_vect PL]; 
    
    
    for j=[2,3,4]   % 3y/5y/7y
        if t==1 && abs(SR_trading(t,j)-SR_model_trading(t,j)) > thresh_open
            % EXECUTE TRADES
            [P,B,C] = M.P(fac, (0.5:0.5:mat(D))');
            [~,J] = SwapJacobian(P,B,C,mat); % compute Jacobian
   
            % if deviation is positive, buy belly
            if SR_trading(t,j)-SR_model_trading(t,j) > 0
                ntl_belly = 1;
            else % otherwise, sell belly
                ntl_belly = -1;
            end
            SS = 1; MM = j; LL = 5;
            % PV01s for each swap
            pv01_belly = sum(P(1:mat(j)*2))/2;
            pv01_2y = sum(P(1:mat(SS)*2))/2;
            pv01_10y = sum(P(1:mat(LL)*2))/2;
            
            % hedge ratios
            denom = (J(LL,1)*J(SS,2) - J(LL,2)*J(SS,1));
            ntl_2y = ntl_belly*pv01_belly/pv01_2y*(J(LL,2)*J(MM,1) - J(LL,1)*J(MM,2))/denom;
            ntl_10y = ntl_belly*pv01_belly/pv01_10y*(J(MM,2)*J(SS,1) - J(MM,1)*J(SS,2))/denom;
            
            % STORE TRADE
            this_day=input_swap_dates(begin_trading+t-1);
            MyPort=portfolio(this_day, Maturities(j));
            swap1_enter_day=this_day;
            
            MyPort.append_swaps(swap1_enter_day, addtodate(this_day, Maturities(j), 'year'), ntl_belly);
            MyPort.append_swaps(swap1_enter_day, addtodate(this_day, Maturities(1), 'year'), ntl_2y);
            MyPort.append_swaps(swap1_enter_day, addtodate(this_day, Maturities(5), 'year'), ntl_10y);

                        
            portfolio_vector=[portfolio_vector MyPort];
            % eg. obj = Trade(t, j, ntl_belly, ntl_2y, ntl_10y)
        elseif  t==1 && abs(SR_trading(t,j)-SR_model_trading(t,j)) < thresh_close
            for i=1:length(portfolio_vector)
                Port=portfolio_vector(i);
                if Port.tag==Maturities(j)
                    CloseContracts=true;
                    EvaluatePortfolioAtDate=input_swap_dates(begin_trading+t-1);
                    Port.evaluate(ThisSwapRate, EvaluatePortfolioAtDate, CloseContracts);
                end
            end
        end
    end
end
