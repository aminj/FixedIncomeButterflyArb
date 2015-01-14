classdef swaps<handle
    properties
        ContractDate;
        MaturityDate;
        Position;
        SellDate;
        ClosedInd;
        NetProfit;
    end
    methods
        function obj=swaps(ConDate,MatDate, Pos)
            obj.ContractDate=ConDate;
            obj.MaturityDate=MatDate;
            obj.Position=Pos;
            obj.ClosedInd=false;
            obj.NetProfit=0;
        end
        
        function out=left_to_maturity(obj, date)
            out=date_diff(date, obj.MaturityDate);
        end
        
        function out=maturity(obj)
            BuyMat=obj.left_to_maturity(obj.ContractDate);
            out=BuyMat(1)/12;
        end
        
        function out=rate(obj, ThisSwapRates)
            out=ThisSwapRates(obj.ContractDate, obj.Maturiy);
        end
        
        function out=evaluate(obj, SwapRates, SellDate)
            %SwapRates should be in the form of @(date,maturity) SwapRate(date, maturity)
            %all the dates input should be datenum
            swap_freq=.25;
            swap_int=swap_freq*12;
            BuyMat=obj.left_to_maturity(obj.ContractDate);
            Rem2Mat=obj.left_to_maturity(SellDate);
            last_LIBOR_date=addtodate(obj.MaturityDate, -ceil(Rem2Mat(1)/swap_int)*swap_int , 'month');

            ZeroMaturity=Rem2Mat;
            LIBOR=SwapRate2Zero(@(mat) SwapRates(last_LIBOR_date, mat), 3, swap_freq);
            BN=SwapRate2Zero(@(mat) SwapRates(SellDate, mat), ZeroMaturity, swap_freq);
            fixed_rate=SwapRates(obj.ContractDate, BuyMat(1)/12);
            N=length(BN);
            fixed_leg=sum(fixed_rate./(1+BN).^(1:N))+1/(1+BN(N))^N;
            floating_leg=(1+LIBOR(2))/BN(1);
            SwapPrice=floating_leg-fixed_leg;
%             rf_buy=SwapRates(obj.ContractDate, BuyMat(1)/12);
%             rf_sell=SwapRates(SellDate, Rem2Mat(1)/12);
%             SwapPrice=(1-BN(end))*(rf_buy/rf_sell-1);
            out=SwapPrice*obj.Position;
        end
        
        function price=close(obj, SwapRates, SellDate)
            if SellDate<obj.MaturityDate
                price=obj.evaluate(SwapRates,SellDate);
            else
                price=0;
            end
                
            obj.ClosedInd=true;
            obj.SellDate=SellDate;
            obj.NetProfit=price;
        end
    end
end

           