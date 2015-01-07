clear; close all;

CALIBRATE = 1;  % set to 1 to run optimization

SR_all = csvread('Swap Rates-BB_Weekly.csv',1,1);
mat = [2,3,5,7,10]; D = numel(mat);

window_calibration = 1101:1257; % Jan 2010 - Dec 2012
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
SR_trading = SR_all(1258:end,:); % Jan 2013+ 
[~, factors_trading] = Kalman(params_opt, SR_trading, factors_calibration(:,end), P_XX_last);
M = Vasicek2F(params_opt);
SR = @(fac, T) Zero2SwapRate(T, @(tau) M.P(fac, tau));
SR_model = [SR(factors_trading, 2) ...
           SR(factors_trading, 3) ...
           SR(factors_trading, 5) ...
           SR(factors_trading, 7) ...
           SR(factors_trading, 10)];
SR_model = SR_model(1:end-1,:);
n = size(SR_model,1);

% plot out-of-sample deviations: actual vs model
figure;
subplot(2,1,1); plot((1:n)', 100*(SR_trading(:,1)-SR_model(:,1)), 'r-'); title('2Y: Act-Mdl (bps)');
subplot(2,1,2); plot((1:n)', 100*(SR_trading(:,5)-SR_model(:,5)), 'r-'); title('10Y: Act-Mdl (bps)');

figure;
subplot(3,1,1); plot((1:n)', 100*(SR_trading(:,2)-SR_model(:,2)), 'r-'); title('3Y: Act-Mdl (bps)');
subplot(3,1,2); plot((1:n)', 100*(SR_trading(:,3)-SR_model(:,3)), 'r-'); title('5Y: Act-Mdl (bps)');
subplot(3,1,3); plot((1:n)', 100*(SR_trading(:,4)-SR_model(:,4)), 'r-'); title('7Y: Act-Mdl (bps)');

for t=1:n
    fac = factors_trading(:,t);
    thresh_open = 0.1; % trading thresholds
    thresh_close = 0.02;
    
    for j=[2,3,4]   % 3y/5y/7y
        if abs(SR_trading(t,j)-SR_model(t,j)) > thresh_open
            % EXECUTE TRADES
            [P,B,C] = M.P(fac, (0.5:0.5:mat(D))');
            [~,J] = SwapJacobian(P,B,C,mat); % compute Jacobian
   
            % if deviation is positive, buy belly
            if SR_trading(t,j)-SR_model(t,j) > 0
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
            % eg. obj = Trade(t, j, ntl_belly, ntl_2y, ntl_10y)
        elseif abs(SR_trading(t,j)-SR_model(t,j)) < thresh_close
            % CLOSEOUT TRADES
%             profit = ntl_belly*value_belly + ...
%                      ntl_2y*value_2y + ...
%                      ntl_10y*value_10y;
            
        end
    end
end
