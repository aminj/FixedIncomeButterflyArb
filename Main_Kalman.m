clear; close all;

CALIBRATE = 0;  % set to 1 to run optimization (takes a while)
DEVPLOTS = 0;  % mispricing plots
PNLPLOTS = 1;  % P&L plots

%MONTHLY: [data, ~, draw] = xlsread('Swap Rates-BB.xlsx', 'Par Rates');
%MONTHLY: [libor] = xlsread('Swap Rates-BB.xlsx', 'LIBOR3M');

[data, ~, draw] = xlsread('Swap Rates-BB_Weekly.xlsx', 'Par Rates');
[libor] = xlsread('Swap Rates-BB_Weekly.xlsx', 'LIBOR3M');

%draw = csvread('Swap Rates-BB.csv');

Maturities=[2 3 5  7 10];
Mat_vect=  [1 4 7 10 13];

% dur_win=3:314; %monthly
dur_win=3:1355;
input_swap_rates=cell2mat(draw(dur_win,Mat_vect+1));
input_swap_dates=[];

for i = dur_win
    input_swap_dates(i-2)=datenum(cell2mat(draw(i,1)));
end

ThisSwapRate=@(thisdate,thismat) SwapRate([libor input_swap_rates], [.25 Maturities], input_swap_dates, thisdate, thismat);

D = numel(Maturities);

%%% SET WINDOWS %%%
window_calibration = 1101:1257; % Jan 2010 - Dec 2012
trading_window = 1258:1353;     % Jan 2013 - Oct 2014
%%%%%%%%%%%%%%%%%%%

SR_calibration = input_swap_rates(window_calibration,:);

% params_init =[  0.3165
%                 0.0162
%                 0.0108
%                -0.0185
%                 0.0150
%                 0.0057  ];  % for Dec 2002 - Dec 2011
          
params_init =[  0.0140
                0.0137
                0.0058
                0.1676
                0.0144
                0.0077  ];  % for Jan 2010 - Dec 2012
            
% params_init =[  0.0357
%                 0.0268
%                 0.0066
%                 0.3121
%                 0.0219
%                 0.0096  ];  % for Jan 2002 - Dec 2004
    
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

% final model
Model = Vasicek2F(params_opt);
ModelSwapRate = @(fac, T) Zero2SwapRate(T, @(tau) Model.P(fac, tau));

% fit factors to price 2y/10y exactly (small adjustment)
nCalibrationDays = numel(window_calibration);
factors_calibration = zeros(2, nCalibrationDays);
for t = 1:nCalibrationDays
    factors_calibration(:, t) = fsolve(@(fac) [ModelSwapRate(fac, 2) - SR_calibration(t,1) ; ...
                                           ModelSwapRate(fac, 10) - SR_calibration(t,5)], ...
                                           [0;0], optimoptions('fsolve','Display','off'));
end
SR_model_calibration = [ModelSwapRate(factors_calibration, 2) ...
                        ModelSwapRate(factors_calibration, 3) ...
                        ModelSwapRate(factors_calibration, 5) ...
                        ModelSwapRate(factors_calibration, 7) ...
                        ModelSwapRate(factors_calibration, 10)];

% start trading out of sample
begin_trading = trading_window(1);
SR_trading = input_swap_rates(trading_window,:);
libor_trading = libor(trading_window);
nTradingDays = numel(libor_trading);

factors_trading = zeros(2, nTradingDays);
for t = 1:nTradingDays
    factors_trading(:, t) = fsolve(@(fac) [ModelSwapRate(fac, 2) - SR_trading(t,1) ; ...
                                           ModelSwapRate(fac, 10) - SR_trading(t,5)], ...
                                           [0;0], optimoptions('fsolve','Display','off'));
end
SR_model_trading = [ModelSwapRate(factors_trading, 2) ...
                       ModelSwapRate(factors_trading, 3) ...
                       ModelSwapRate(factors_trading, 5) ...
                       ModelSwapRate(factors_trading, 7) ...
                       ModelSwapRate(factors_trading, 10)];
                   
% % get factors from calibrated model (Kalman version)
% [~, factors_calibration, P_XX_last] = Kalman(params_opt, SR_calibration);
% [~, factors_trading] = Kalman(params_opt, SR_trading, factors_calibration(:,end), P_XX_last);

if DEVPLOTS
%     figure;
%     subplot(2,1,1); plot((1:nCalibrationDays)', 100*(SR_calibration(:,1)-SR_model_calibration(:,1)), 'r-'); title('2Y: Act-Mdl (bps)');
%     subplot(2,1,2); plot((1:nCalibrationDays)', 100*(SR_calibration(:,5)-SR_model_calibration(:,5)), 'r-'); title('10Y: Act-Mdl (bps)');

%     figure('Color','White');
%     subplot(3,1,1); plot((1:nCalibrationDays)', 100*(SR_calibration(:,2)-SR_model_calibration(:,2)), 'r-'); title('3Y: Act-Mdl (bps)');
%     subplot(3,1,2); plot((1:nCalibrationDays)', 100*(SR_calibration(:,3)-SR_model_calibration(:,3)), 'r-'); title('5Y: Act-Mdl (bps)');
%     subplot(3,1,3); plot((1:nCalibrationDays)', 100*(SR_calibration(:,4)-SR_model_calibration(:,4)), 'r-'); title('7Y: Act-Mdl (bps)');

%     figure;
%     subplot(2,1,1); plot((1:nTradingDays)', 100*(SR_trading(:,1)-SR_model_trading(:,1)), 'r-'); title('2Y: Act-Mdl (bps)');
%     subplot(2,1,2); plot((1:nTradingDays)', 100*(SR_trading(:,5)-SR_model_trading(:,5)), 'r-'); title('10Y: Act-Mdl (bps)');

    figure('Color','White');
%     subplot(3,1,1); plot((1:nTradingDays)', 100*(SR_trading(:,2)-SR_model_trading(:,2)), 'r-'); title('3Y: Actual - Model (bps)');
%     subplot(3,1,2); 
    plot((1:nTradingDays)', 100*(SR_trading(:,3)-SR_model_trading(:,3)), 'r-'); title('5Y: Actual - Model (bps)');
%     subplot(3,1,3); plot((1:nTradingDays)', 100*(SR_trading(:,4)-SR_model_trading(:,4)), 'r-'); title('7Y: Actual - Model (bps)');
%
end

thresh_open = 0.15; % trading thresholds
thresh_close = 0.02;

portfolios= cell(3,1);
pfo_fly_ind = [2 3 4];

PL_vect=[]; PL_vect_approx=[];
Cash = 0;
tcost = 0.005; % transaction cost: 0.5bp off of swap rate

for t=1:nTradingDays
    fac = factors_trading(:,t); % today's factors
    currentDate=input_swap_dates(begin_trading+t-1);
    totalPfoValue = 0;
    approxPL = 0;
    Zero = @(T1) SwapSpline2ZeroSpline(@(T2) ThisSwapRate(currentDate, T2), T1);
                
    % loop thru each butterfly
    for j=1:3
        deviation = SR_trading(t,pfo_fly_ind(j))-SR_model_trading(t,pfo_fly_ind(j));
        belly_maturity = Maturities(pfo_fly_ind(j));
        rebal = false;
        bflyValue = 0;
        
        % value each portfolio
        if ~isempty(portfolios{j}) 
            bflyValue=portfolios{j}.evaluate(Zero, currentDate);
           
            % approximation for sanity check
            approxMtM = -pv01_belly/100*(SR_trading(t,pfo_fly_ind(j))-SR_trading(t-1,pfo_fly_ind(j)));
            approxCarry = 1/52/100*(SR_trading(t-1,pfo_fly_ind(j)) - libor_trading(t-1));
            approxPL = approxPL + portfolios{j}.swap_list(1).Position*(approxMtM+approxCarry);
            
            approxMtM = -pv01_2y/100*(SR_trading(t,1)-SR_trading(t-1,1));
            approxCarry = 1/52/100*(SR_trading(t-1,1) - libor_trading(t-1));
            approxPL = approxPL + portfolios{j}.swap_list(2).Position*(approxMtM+approxCarry);
            
            approxMtM = -pv01_10y/100*(SR_trading(t,5)-SR_trading(t-1,5));
            approxCarry = 1/52/100*(SR_trading(t-1,5) - libor_trading(t-1));
            approxPL = approxPL + portfolios{j}.swap_list(3).Position*(approxMtM+approxCarry);
            
            % rebalance if 3 months has passed (and convergence hasn't happened)
            if months(portfolios{j}.update_date, currentDate) >=3 
                rebal=true;
            end
            
            if rebal || ...  % rebalance 
               abs(deviation) < thresh_close || ... % within threshold
               sign(deviation)==-sign(portfolios{j}.swap_list(1).Position)  % overcorrected
           
                if abs(deviation) < thresh_close || sign(deviation)==-sign(portfolios{j}.swap_list(1).Position)
                    rebal = false;
                end
            	Cash = Cash+bflyValue;  % cash out portfolio
                bflyValue = 0;
                portfolios{j}={};
            end
        end
        
        % if no active trade & deviation breaches threshold, put one on
        if isempty(portfolios{j}) && ...
                    ( (abs(deviation) > thresh_open) || ...  % new trade
                    rebal ) % rebalance
           
            % EXECUTE TRADES
            [P,B,C] = Model.P(fac, (0.5:0.5:Maturities(D))');
            [~,J] = SwapJacobian(P,B,C,Maturities); % compute Jacobian

            % if deviation is positive, buy belly
            if deviation > 0
                ntl_belly = 10000;
            else % otherwise, sell belly
                ntl_belly = -10000;
            end
            SS = 1; MM = pfo_fly_ind(j); LL = 5;
            % PV01s for each swap
            pv01_belly = sum(P(1:belly_maturity*2))/2;
            pv01_2y = sum(P(1:Maturities(SS)*2))/2;
            pv01_10y = sum(P(1:Maturities(LL)*2))/2;

            % hedge ratios
            denom = (J(LL,1)*J(SS,2) - J(LL,2)*J(SS,1));
            ntl_2y = ntl_belly*pv01_belly/pv01_2y*(J(LL,2)*J(MM,1) - J(LL,1)*J(MM,2))/denom;
            ntl_10y = ntl_belly*pv01_belly/pv01_10y*(J(MM,2)*J(SS,1) - J(MM,1)*J(SS,2))/denom;

            % STORE TRADE
            
            pfo=portfolio(currentDate);
            pfo.append_swaps(currentDate, addtodate(currentDate, belly_maturity, 'year'), ntl_belly, ...
                             SR_trading(t,pfo_fly_ind(j))-tcost*sign(ntl_belly), libor_trading(t));  
            pfo.append_swaps(currentDate, addtodate(currentDate, 2, 'year'), ntl_2y, ...
                             SR_trading(t,1)-tcost*sign(ntl_2y), libor_trading(t));
            pfo.append_swaps(currentDate, addtodate(currentDate, 10, 'year'), ntl_10y, ...
                             SR_trading(t,5)-tcost*sign(ntl_10y), libor_trading(t));

            portfolios{j}=pfo;
        end
        totalPfoValue = totalPfoValue + bflyValue;
    end
    
    PL_vect=[PL_vect Cash+totalPfoValue]; 
    PL_vect_approx=[PL_vect_approx approxPL];
end

if PNLPLOTS
%     figure('Color','White');
%     plot((1:nTradingDays)', [0 diff(PL_vect)], 'r-', (1:nTradingDays)', PL_vect_approx, 'b-'); title('P&L (actual vs. approx)');
figure('Color','White');
plotyy((1:nTradingDays)', 100*(SR_trading(:,2)-SR_model_trading(:,2)), ...
       (1:nTradingDays)', PL_vect);
   legend({'5Y (Actual - Model)'; 'P&L'}, 'Location', 'Best');
   hold on;
% plot((1:nTradingDays)',100*(SR_trading(:,3)-SR_model_trading(:,3)));
% plot((1:nTradingDays)',100*(SR_trading(:,4)-SR_model_trading(:,4)));
plot((1:nTradingDays)',thresh_open*100,'r-');
plot((1:nTradingDays)',-thresh_open*100,'r-');
plot((1:nTradingDays)',thresh_close*100,'k-');
plot((1:nTradingDays)',-thresh_close*100,'k-');
title('Price Deviations & Cumulative P&L');
hold off;
    
%     
%     
end