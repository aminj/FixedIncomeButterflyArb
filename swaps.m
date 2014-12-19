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
            DateVec=@(d) datevec(datestr(d));
            out=DateVec(obj.MaturityDate)-DateVec(date);
        end
        
        function out=maturity(obj)
            BuyMat=obj.left_to_maturity(obj.ContractDate);
            out=BuyMat(1)+BuyMat(2)/12;
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
            if mod(Rem2Mat(2), swap_int)==0
%                 if Rem2Mat(3)==0
                    ZeroMaturity=Rem2Mat;
                    BN=SwapRate2Zero(@(mat) SwapRates(SellDate, mat), ZeroMaturity);
                    rf_buy=SwapRates(obj.ContractDate, BuyMat(1)+BuyMat(2)/12);
                    rf_sell=SwapRates(SellDate, Rem2Mat(1)+Rem2Mat(2)/12);
                    SwapPrice=(1-BN(end))*(rf_buy/rf_sell-1);
%                 end
            end
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

           