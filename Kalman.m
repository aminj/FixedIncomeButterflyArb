function [RMSE, X, P_XX] = Kalman(params, S, X_init, P_XX_init)
n = size(S,1);
M = Vasicek2F(params);

dt = 1/12;
CONST = [M.mu1*(1-exp(-M.q1*dt)); M.mu2*(1-exp(-M.q2*dt))];
F = [exp(-M.q1*dt), 0;
     0,             exp(-M.q2*dt)];
X = zeros(2,n+1);
mat = [2,3,5,7,10];
D = numel(mat);

% initial values for Kalman filter
if ~exist('X_init', 'var')
    X(:,1) = [M.mu1; M.mu2];
else
    X(:,1) = X_init;
end
if ~exist('P_XX_init', 'var')
    P_XX = [M.s1^2/(2*M.q1),   0;
     0,                 M.s2^2/(2*M.q2)];
else
    P_XX = P_XX_init;
end

Q = [M.s1^2/(2*M.q1)*(1-exp(-2*M.q1*dt)), 0; 
             0,                 M.s2^2/(2*M.q2)*(1-exp(-2*M.q2*dt))];
R = eye(5)*.03^2;  % assume 3bp measurement error
SUMSQDEV = 0;
for t = 1:n
    [P,B,C] = M.P(X(:,t), (0.5:0.5:mat(D))');
    [S_calc,J] = SwapJacobian(P,B,C,mat); % compute Jacobian
    P_YY = J*P_XX*J' + R; % update cov of swap rates
    DEV = S(t,:)' - S_calc; % deviation of estimates from actual
    K = (P_XX*J')/(P_YY); % gain matrix
    X(:,t) = X(:,t) + K*DEV; % X(t|t), update estimate of factors
    P_XX_T = P_XX - K*J*P_XX; % update estimate of factor variances
    X(:,t+1) = CONST + F*X(:,t); % X(t|t-1), transition system
    P_XX = F*P_XX_T*F' + Q;
    SUMSQDEV = SUMSQDEV + sum(DEV.^2);
end
RMSE = sqrt(1/n*SUMSQDEV);
if isnan(RMSE)
    RMSE = 10^6;
end