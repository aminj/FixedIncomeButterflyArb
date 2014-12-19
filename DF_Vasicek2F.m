function P = DF_Vasicek2F(params, factors, tau)
% mostly following notation of Moreno (2003)

% dX = q1(mu1-X)dt + ?1dW1 
% dY = q2(mu2-Y)dt + ?2dW1 

X = factors(1, :)';
Y = factors(2, :)';

q1 = params(1);
mu1 = params(2);
s1 = params(3);

q2 = params(4);
mu2 = params(5);
s2 = params(6);

B = (1-exp(-q1.*tau))./q1;
C = (1-exp(-q2.*tau))./q2;

XS = mu1 - s1^2/(2*q1^2);
YS = mu2 - s2^2/(2*q2^2);

A1 = exp(-s1^2/(4*q1).*B.^2+XS*(B-tau));
A2 = exp(-s2^2/(4*q2).*C.^2+YS*(C-tau));
A = A1.*A2;

P = bsxfun(@times,A,exp(-bsxfun(@times,B,X)-bsxfun(@times,C,Y)));