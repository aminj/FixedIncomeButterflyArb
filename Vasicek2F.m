classdef Vasicek2F
    
    % dX = q1(mu1-X)dt + ?1dW1 
    % dY = q2(mu2-Y)dt + ?2dW1 
    
    properties
        q1;
        mu1;
        s1;
        q2;
        mu2;
        s2;
    end

    methods
        function obj = Vasicek2F(params)
            obj.q1 = params(1);
            obj.mu1 = params(2);
            obj.s1 = params(3);

            obj.q2 = params(4);
            obj.mu2 = params(5);
            obj.s2 = params(6);
        end
        
        function [P,B,C] = P(obj, factors, tau)
            X = factors(1, :)';
            Y = factors(2, :)';
            
            B = (1-exp(-obj.q1.*tau))./obj.q1;
            C = (1-exp(-obj.q2.*tau))./obj.q2;

            XS = obj.mu1 - obj.s1^2/(2*obj.q1^2);
            YS = obj.mu2 - obj.s2^2/(2*obj.q2^2);

            A1 = exp(-obj.s1^2/(4*obj.q1).*B.^2+XS*(B-tau));
            A2 = exp(-obj.s2^2/(4*obj.q2).*C.^2+YS*(C-tau));
            A = A1.*A2;

            P = bsxfun(@times,A,exp(-bsxfun(@times,B,X)-bsxfun(@times,C,Y)));
        end
    end

end

