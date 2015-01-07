function [S,J] = SwapJacobian(P, B, C, mat)
D = numel(mat);
S = zeros(D,1);
J = zeros(D,2);

for i = 1:D
    M = mat(i);
    numer = 200*(1 - P(M*2));
    denom = sum(P(1:M*2));

    dNumerX = 200*B(M*2)*P(M*2);
    dDenomX = -sum(B(1:M*2).*P(1:M*2));

    dNumerY = 200*C(M*2)*P(M*2);
    dDenomY = -sum(C(1:M*2).*P(1:M*2));

    S(i) = numer/denom;
    J(i,1) = (dNumerX*denom - dDenomX*numer)/denom^2;
    J(i,2) = (dNumerY*denom - dDenomY*numer)/denom^2;
end