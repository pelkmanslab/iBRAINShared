classdef RunningStat < handle
    
    properties (Constant=true)
        % Possible values are: {'mex', 'matlab'}
        %use_impl = 'mex';
        use_impl = 'matlab';
     end

    properties (Access='private')
       % (running) sum of square deviations from mean
       ss;
       % *(running) mean
       m;
       n = 0;
       % weight of items seen
       total_weight;
       is_started = false;
    end
    
    methods (Static)        
        function instance = new()
            if strcmp(RunningStat.use_impl, 'mex')
                instance = MexRunningStatImpl();
            else
                instance = MatlabRunningStatImpl();
            end
        end
    end
end
