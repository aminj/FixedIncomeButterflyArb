classdef portfolio<handle
    properties
        swap_list; %PxN, each column consists of a swap class
%         portfolio_value;
        update_date;
%         tag;
    end
    methods
        function obj=portfolio(dt)
            obj.update_date=dt;
            obj.swap_list=swaps.empty;
%             obj.tag=mytag;
            %portfolio_value{1}={ConsDate 0};
        end
        
        function out=evaluate(obj,Zero, EvalDate)
            Value=0;
            for i=1:size(obj.swap_list,2)
%                 if obj.swap_list(i).ClosedInd
%                     Value=Value+obj.swap_list(i).NetProfit;
%                 else
%                     if CloseInd
%                         Value=Value+obj.swap_list(i).close(SwapRate,EvalDate);
%                     else
                        Value=Value+obj.swap_list(i).evaluate(Zero,EvalDate);
%                     end
%                 end
            end
%             obj.portfolio_value{end+1}={EvalDate Value};
            out=Value;
        end
        
        function append_swaps(obj, ConDate, MatDate, Pos, SwapRate, LIBORRate)
            NewSwap=swaps(ConDate, MatDate, Pos, SwapRate, LIBORRate);
            obj.swap_list(end+1)=NewSwap;
        end
            
    end
end

                    
                
        
            
    